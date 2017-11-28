# This service class is a decorator for the Import model,
# it handles additional behaviour regarding importing from CSV files.

require 'csv'

class CsvImport
  delegate :account_list, to: :@import

  def self.supported_headers
    {
      church: _('Church'),
      city: _('City'),
      pledge_amount: _('Commitment Amount'),
      pledge_currency: _('Commitment Currency'),
      pledge_frequency: _('Commitment Frequency'),
      country: _('Country'),
      email_1: _('Email 1'),
      email_2: _('Email 2'),
      envelope_greeting: _('Envelope Greeting'),
      first_name: _('First Name'),
      full_name: _('Full Name'),
      greeting: _('Greeting'),
      last_name: _('Last Name'),
      likely_to_give: _('Likely To Give'),
      metro_area: _('Metro Area'),
      newsletter: _('Newsletter'),
      notes: _('Notes'),
      phone_1: _('Phone 1'),
      phone_2: _('Phone 2'),
      phone_3: _('Phone 3'),
      referred_by: _('Referred By'),
      region: _('Region'),
      send_appeals: _('Send Appeals?'),
      spouse_email: _('Spouse Email'),
      spouse_first_name: _('Spouse First Name'),
      spouse_last_name: _('Spouse Last Name'),
      spouse_phone: _('Spouse Phone'),
      state: _('State'),
      status: _('Status'),
      street: _('Street'),
      tags: _('Tags'),
      website: _('Website'),
      zip: _('Zip')
    }
  end

  def self.required_headers
    {
      first_name: _('First Name'),
      last_name: _('Last Name')
    }
  end

  def self.constants
    constants_exhibit = ConstantList.new.to_exhibit
    {
      pledge_currency: constants_exhibit.pledge_currencies_translated_hashes,
      pledge_frequency: constants_exhibit.pledge_frequency_translated_hashes,
      likely_to_give: constants_exhibit.assignable_likely_to_give_translated_hashes,
      newsletter: constants_exhibit.assignable_send_newsletter_translated_hashes,
      send_appeals: constants_exhibit.send_appeals_translated_hashes,
      status: constants_exhibit.status_translated_hashes
    }
  end

  def self.transform_array_to_hash_with_underscored_keys(array)
    array.each_with_object({}.with_indifferent_access) do |value, hash|
      hash[value&.parameterize&.underscore] = value
      hash
    end
  end

  def initialize(import)
    @import = import
  end

  def each_row
    CsvFileReader.new(@import.file_path).each_row do |csv_row|
      yield(csv_row)
    end
  end

  def import
    raise 'Attempted an invalid import! Aborting.' if @import.invalid?
    raise 'Attempted an import that is in preview! Aborting.' if @import.in_preview?

    batch = Sidekiq::Batch.new
    batch.description = "CsvImport #{@import.id} #import"
    batch.on(:complete, 'CsvImportBatchCallbackHandler', import_id: @import.id)
    batch.jobs do
      each_row do |csv_row|
        CsvImportContactWorker.perform_async(@import.id, csv_row.headers, csv_row.fields)
      end
    end

    # If there are no jobs the Batch callbacks won't fire,
    # in that case treat this as a synchronous job by returning false.
    !batch.jids.empty? ? true : false
  end

  def file_constants_for_mpdx_header(mpdx_header)
    @import.file_constants[@import.file_headers_mappings[mpdx_header]]&.to_a
  end

  def sample_contacts
    sample_contacts = @import.file_row_samples.collect do |sample_row|
      contact_from_file_line(sample_row)
    end.compact
    generate_uuids_for_contacts(sample_contacts)
  end

  def update_cached_file_data
    assign_cached_file_data
    @import.save
  end

  def generate_csv_from_file_row_failures
    csv = CSV.generate_line(['Error Message'] + @import.file_headers.values)
    @import.file_row_failures.each_with_object(csv) { |failure, string| string << CSV.generate_line(failure) }
    csv
  end

  private

  def assign_cached_file_data
    @import.file_headers = read_file_headers_from_file_contents if @import.file_headers.blank?
    @import.file_constants = read_file_constants_from_file_contents if @import.file_constants.blank?
    @import.file_row_samples = read_file_row_samples_from_file_contents if @import.file_row_samples.blank?
  end

  def read_file_headers_from_file_contents
    header_row = nil
    each_row do |csv_row|
      header_row = csv_row.headers
      break
    end
    self.class.transform_array_to_hash_with_underscored_keys(header_row)
  end

  def read_file_constants_from_file_contents
    CsvFileConstantsReader.new(@import.file_path).constants
  end

  def read_file_row_samples_from_file_contents
    samples = []
    each_row do |csv_row|
      row_fields = csv_row.fields
      samples << row_fields
      break if samples.size >= 4
    end
    samples
  end

  def contact_from_file_line(line)
    line = CSV.new(line).first unless line.is_a?(Array)
    csv_row = CSV::Row.new(@import.file_headers.values, line)
    CsvRowContactBuilder.new(csv_row: csv_row, import: @import).build
  end

  def generate_uuids_for_contacts(contacts)
    objects_needing_uuid = contacts.collect do |contact|
      [
        contact,
        contact.primary_person,
        contact.spouse,
        contact.addresses,
        contact.primary_person&.email_addresses,
        contact.spouse&.email_addresses,
        contact.primary_person&.phone_numbers,
        contact.spouse&.phone_numbers
      ]
    end.flatten.compact
    objects_needing_uuid.each { |record| record.uuid ||= SecureRandom.uuid }
    contacts
  end
end
