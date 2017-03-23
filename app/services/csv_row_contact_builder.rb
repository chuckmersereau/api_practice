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

  delegate :account_list, to: :import, prefix: false

  attr_accessor :csv_row, :import, :contact, :person, :spouse

  def contact_from_csv_row
    rebuild_csv_row_with_mpdx_headers_and_mpdx_constants

    return if true?(csv_row['Do Not Import?'])

    build_contact
    build_addresses
    build_tags
    build_primary_person
    build_email_addresses
    build_phone_numbers
    build_spouse_person

    contact
  end

  def build_contact
    self.contact = account_list.contacts.build(
      church_name: csv_row['Church'],
      name: csv_row['Contact Name'],
      greeting: csv_row['Greeting'],
      envelope_greeting: csv_row['Envelope Greeting'],
      status: csv_row['Status'],
      pledge_amount: csv_row['Commitment Amount'],
      notes: csv_row['Notes'],
      pledge_frequency: csv_row['Commitment Frequency'],
      send_newsletter: csv_row['Newsletter'],
      pledge_currency: csv_row['Commitment Currency'],
      likely_to_give: csv_row['Likely To Give'],
      no_appeals: !true?(csv_row['Send Appeals?']),
      website: csv_row['Website']
    )
  end

  def build_addresses
    return if csv_row['Street'].blank?

    contact.addresses.build(
      street: csv_row['Street'],
      city: csv_row['City'],
      state: csv_row['State'],
      postal_code: csv_row['Zip'],
      country: csv_row['Country'],
      metro_area: csv_row['Metro Area'],
      region: csv_row['Region'],
      primary_mailing_address: true
    )
  end

  def build_tags
    contact.tag_list = csv_row['Tags']
    contact.tag_list.add(import.tags, parse: true) if import.tags.present?
  end

  def build_primary_person
    self.person = Person.new(first_name: csv_row['First Name'].presence || csv_row['Contact Name'],
                             last_name: csv_row['Last Name'])
    contact.primary_person = person
  end

  def build_email_addresses
    person.email_addresses.build(email: csv_row['Email 1'],
                                 primary: true) if csv_row['Email 1'].present?
    person.email_addresses.build(email: csv_row['Email 2'],
                                 primary: person.email_addresses.blank?) if csv_row['Email 2'].present?
  end

  def build_phone_numbers
    person.phone_numbers.build(number: csv_row['Phone 1'],
                               primary: true) if csv_row['Phone 1'].present?
    person.phone_numbers.build(number: csv_row['Phone 2'],
                               primary: person.phone_numbers.blank?) if csv_row['Phone 2'].present?
    person.phone_numbers.build(number: csv_row['Phone 3'],
                               primary: person.phone_numbers.blank?) if csv_row['Phone 3'].present?
  end

  def build_spouse_person
    return if csv_row['Spouse First Name'].blank?

    spouse = Person.new(first_name: csv_row['Spouse First Name'],
                        last_name: csv_row['Spouse Last Name'].presence || csv_row['Last Name'])
    spouse.email_addresses.build(email: csv_row['Spouse Email'],
                                 primary: true) if csv_row['Spouse Email'].present?
    spouse.phone_numbers.build(number: csv_row['Spouse Phone'],
                               primary: true) if csv_row['Spouse Phone'].present?

    contact.spouse = spouse
  end

  def true?(val)
    val.to_s.casecmp('true').zero?
  end

  def rebuild_csv_row_with_mpdx_headers_and_mpdx_constants
    self.csv_row = rebuild_csv_row_with_mpdx_headers(csv_row)
    self.csv_row = rebuild_csv_row_with_mpdx_constants(csv_row)
  end

  def rebuild_csv_row_with_mpdx_headers(old_csv_row)
    return old_csv_row if import.file_headers_mappings.blank?
    headers = import.file_headers_mappings.keys
    fields = import.file_headers_mappings.values.collect { |csv_header| old_csv_row[csv_header] }
    CSV::Row.new(headers, fields)
  end

  def rebuild_csv_row_with_mpdx_constants(old_csv_row)
    return old_csv_row if import.file_constants_mappings.blank?
    new_csv_row = old_csv_row
    import.file_constants_mappings.each do |mpdx_constant_header, mpdx_constant_mappings|
      value_to_change = old_csv_row[mpdx_constant_header]
      mpdx_constant_value = mpdx_constant_mappings.find do |_mpdx_constant_value, csv_constant_value|
        [csv_constant_value].flatten.include?(value_to_change)
      end&.first
      new_csv_row[mpdx_constant_header] = mpdx_constant_value
    end
    new_csv_row
  end
end
