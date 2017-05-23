# This service class is a decorator for the Import model,
# it handles additional behaviour regarding importing from CSV files.

require 'csv'

class CsvImport
  # These are all the header values that MPDX supports for import.
  SUPPORTED_HEADERS = [
    'Church',
    'City',
    'Commitment Amount',
    'Commitment Currency',
    'Commitment Frequency',
    'Country',
    'Email 1',
    'Email 2',
    'Envelope Greeting',
    'First Name',
    'Greeting',
    'Last Name',
    'Likely To Give',
    'Metro Area',
    'Newsletter',
    'Notes',
    'Phone 1',
    'Phone 2',
    'Phone 3',
    'Region',
    'Send Appeals?',
    'Spouse Email',
    'Spouse First Name',
    'Spouse Last Name',
    'Spouse Phone',
    'State',
    'Status',
    'Street',
    'Tags',
    'Website',
    'Zip'
  ].freeze

  # These are the headers that MPDX requires at minimum for CSV import.
  # The user must supply values for at least one of these headers in their CSV (not all are needed).
  REQUIRED_HEADERS = ['First Name', 'Last Name'].freeze

  BOOLEAN_CONSTANTS = ['true', 'false', ''].freeze

  # This is a list of supported headers that have constant values,
  # the user's CSV might have different values so we need to map the user's values to MPDX constant values.
  CONSTANT_HEADERS = {
    'Commitment Currency'  => ConstantList.new.codes << '',
    'Commitment Frequency' => ConstantList.new.pledge_frequencies.keys.collect(&:to_s) << '',
    'Likely To Give'       => ConstantList.new.assignable_likely_to_give << '',
    'Newsletter'           => ConstantList.new.assignable_send_newsletter << '',
    'Send Appeals?'        => BOOLEAN_CONSTANTS,
    'Status'               => ConstantList.new.assignable_statuses << ''
  }.freeze

  delegate :account_list, to: :@import

  def self.supported_headers
    transform_array_to_hash_with_underscored_keys(SUPPORTED_HEADERS.dup)
  end

  def self.required_headers
    transform_array_to_hash_with_underscored_keys(REQUIRED_HEADERS.dup)
  end

  def self.constants
    CONSTANT_HEADERS.keys.each_with_object({}.with_indifferent_access) do |header, hash|
      hash[header.parameterize.underscore] = transform_array_to_hash_with_underscored_keys(CONSTANT_HEADERS[header].dup)
      hash
    end
  end

  # This helper method transforms an Array like ['A Test', 'B Test'] to a Hash like { a_test: 'A Test', b_test: 'B Test' }
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
