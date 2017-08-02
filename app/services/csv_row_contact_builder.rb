# This service class accepts an instance of CSV::Row and an instance of Import and builds a contact record.

class CsvRowContactBuilder
  def initialize(csv_row:, import:)
    @csv_row = csv_row
    @import = import
  end

  def build
    contact_from_csv_row
  end

  private

  delegate :account_list, to: :import
  delegate :constants, to: CsvImport

  attr_accessor :csv_row, :import, :contact, :person, :spouse, :names

  def contact_scope
    account_list.contacts
  end

  def contact_from_csv_row
    rebuild_csv_row_with_mpdx_headers_and_mpdx_constants
    strip_csv_row_fields

    parse_names

    build_contact
    build_addresses
    build_tags
    build_primary_person
    build_email_addresses
    build_phone_numbers
    build_spouse_person
    build_referral

    contact
  end

  def parse_names
    @names = HumanNameParser.new(csv_row['full_name'] || '').parse

    # first_name and last_name columns take precedence over full_name column
    @names[:first_name] = csv_row['first_name'] if csv_row['first_name'].present?
    @names[:last_name] = csv_row['last_name'] if csv_row['last_name'].present?
    @names[:spouse_first_name] = csv_row['spouse_first_name'] if csv_row['spouse_first_name'].present?
    @names[:spouse_last_name] = csv_row['spouse_last_name'].presence || @names[:last_name]

    @names[:full_contact_name] = Contact::NameBuilder.new(@names.to_h).name

    @names = @names.with_indifferent_access
  end

  def build_contact
    self.contact = contact_scope.build(
      church_name: csv_row['church'],
      name: names['full_contact_name'],
      greeting: csv_row['greeting'],
      envelope_greeting: csv_row['envelope_greeting'],
      status: csv_row['status'],
      pledge_amount: csv_row['commitment_amount'],
      notes: csv_row['notes'],
      pledge_frequency: csv_row['commitment_frequency'],
      send_newsletter: csv_row['newsletter'],
      pledge_currency: csv_row['commitment_currency'],
      likely_to_give: csv_row['likely_to_give'],
      no_appeals: !true?(csv_row['send_appeals']),
      website: csv_row['website']
    )
  end

  def build_addresses
    return if csv_row['street'].blank?

    contact.addresses.build(
      street: csv_row['street'],
      city: csv_row['city'],
      state: csv_row['state'],
      postal_code: csv_row['zip'],
      country: csv_row['country'],
      metro_area: csv_row['metro_area'],
      region: csv_row['region'],
      primary_mailing_address: true
    )
  end

  def build_tags
    contact.tag_list = csv_row['tags']
    contact.tag_list.add(import.tags, parse: true) if import.tags.present?
  end

  def build_primary_person
    self.person = Person.new(first_name: names['first_name'],
                             last_name: names['last_name'])
    contact.primary_person = person
  end

  def build_email_addresses
    person.email_addresses.build(email: csv_row['email_1'],
                                 primary: true) if csv_row['email_1'].present?
    person.email_addresses.build(email: csv_row['email_2'],
                                 primary: person.email_addresses.blank?) if csv_row['email_2'].present?
  end

  def build_phone_numbers
    person.phone_numbers.build(number: csv_row['phone_1'],
                               primary: true) if csv_row['phone_1'].present?
    person.phone_numbers.build(number: csv_row['phone_2'],
                               primary: person.phone_numbers.blank?) if csv_row['phone_2'].present?
    person.phone_numbers.build(number: csv_row['phone_3'],
                               primary: person.phone_numbers.blank?) if csv_row['phone_3'].present?
  end

  def build_spouse_person
    return if names['spouse_first_name'].blank?

    spouse = Person.new(first_name: names['spouse_first_name'],
                        last_name: names['spouse_last_name'])
    spouse.email_addresses.build(email: csv_row['spouse_email'],
                                 primary: true) if csv_row['spouse_email'].present?
    spouse.phone_numbers.build(number: csv_row['spouse_phone'],
                               primary: true) if csv_row['spouse_phone'].present?

    contact.spouse = spouse
  end

  def build_referral
    return if csv_row['referred_by'].blank?

    referrer_contact = Contact::FindFromName.new(contact_scope, csv_row['referred_by']).first

    if referrer_contact.blank?
      contact.tag_list.add('Missing Csv Referred By')
      contact.add_to_notes("Referred by: #{csv_row['referred_by']}")
    else
      contact.contact_referrals_to_me.build(referred_by: referrer_contact)
    end
  end

  def true?(val)
    val.to_s.casecmp('true').zero?
  end

  def strip_csv_row_fields
    new_csv_row = csv_row
    strippable_headers = csv_row.headers - csv_file_constants_mappings_facade.header_ids
    strippable_headers.each do |header|
      new_csv_row[header] = csv_row[header]&.strip
    end
    self.csv_row = new_csv_row
  end

  def rebuild_csv_row_with_mpdx_headers_and_mpdx_constants
    self.csv_row = rebuild_csv_row_with_mpdx_headers(csv_row)
    self.csv_row = rebuild_csv_row_with_mpdx_constants(csv_row)
  end

  def rebuild_csv_row_with_mpdx_headers(old_csv_row)
    return old_csv_row if import.file_headers_mappings.blank?
    mpdx_headers = import.file_headers_mappings.keys
    fields = mpdx_headers.collect do |mpdx_header|
      csv_header = import.file_headers[import.file_headers_mappings[mpdx_header]]
      old_csv_row[csv_header]
    end
    CSV::Row.new(mpdx_headers, fields)
  end

  def rebuild_csv_row_with_mpdx_constants(old_csv_row)
    return old_csv_row if import.file_constants_mappings.blank?
    new_csv_row = old_csv_row
    csv_file_constants_mappings_facade.header_ids.each do |mpdx_constant_header|
      value_to_change = old_csv_row[mpdx_constant_header]
      new_csv_row[mpdx_constant_header] = csv_file_constants_mappings_facade.convert_value(mpdx_constant_header, value_to_change)
    end
    new_csv_row
  end

  def csv_file_constants_mappings_facade
    @csv_file_constants_mappings_facade ||= CsvFileConstantsMappingsFacade.new(import.file_constants_mappings)
  end
end
