class CsvImport
  SUPPORTED_HEADERS = [
    'Contact Name', 'Greeting', 'Envelope Greeting', 'Status', 'Commitment Amount', 'Notes',
    'Commitment Frequency', 'Newsletter', 'Commitment Received', 'Tags', 'Mailing Street Address',
    'Mailing City', 'Mailing State', 'Mailing Postal Code', 'Mailing Country', 'First Name',
    'Last Name', 'Primary Email', 'Primary Phone', 'Spouse First Name', 'Spouse Last Name',
    'Spouse Email', 'Spouse Phone'
  ].freeze

  REQUIRED_HEADERS = ['Contact Name', 'First Name'].freeze

  def initialize(import)
    @import = import
    @account_list = import.account_list
  end

  def import
    Contact.transaction { contacts.each(&:save!) }
  end

  def contacts
    CSV.new(@import.file_contents, headers: :first_row).map(&method(:contact_from_line))
  end

  def actual_headers
    CSV.new(@import.file_contents).first
  end

  def contact_from_line(line)
    contact = @account_list.contacts.build(
      name: line['Contact Name'], greeting: line['Greeting'], envelope_greeting: line['Envelope Greeting'],
      status: line['Status'], pledge_amount: line['Commitment Amount'], notes: line['Notes'],
      pledge_frequency: parse_pledge_frequency(line['Commitment Frequency']),
      send_newsletter: parse_send_newsletter(line['Newsletter']),
      pledge_received: true?(line['Commitment Received'])
    )
    contact.tag_list = line['Tags']

    contact.addresses.build(
      street: line['Mailing Street Address'], city: line['Mailing City'], state: line['Mailing State'],
      postal_code: line['Mailing Postal Code'], country: line['Mailing Country'],
      primary_mailing_address: true
    ) if line['Mailing Street Address'].present?
    contact.tag_list.add(@import.tags, parse: true) if @import.tags.present?

    person = Person.new(first_name: line['First Name'], last_name: line['Last Name'])
    contact.primary_person = person
    person.email_addresses.build(email: line['Primary Email'], primary: true) if line['Primary Email'].present?
    person.phone_numbers.build(number: line['Primary Phone'], primary: true) if line['Primary Phone'].present?

    return contact unless line['Spouse First Name'].present?
    spouse = Person.new(first_name: line['Spouse First Name'], last_name: line['Spouse Last Name'])
    contact.spouse = spouse
    spouse.last_name ||= person.last_name
    spouse.email_addresses.build(email: line['Spouse Email'], primary: true) if line['Spouse Email'].present?
    spouse.phone_numbers.build(number: line['Spouse Phone'], primary: true) if line['Spouse Phone'].present?

    contact
  end

  def parse_pledge_frequency(freq_str)
    Contact.pledge_frequencies.invert[freq_str]
  end

  def parse_send_newsletter(newsletter_str)
    newsletter_str.gsub('None', '') if newsletter_str
  end

  def true?(val)
    val.to_s.upcase.in?(%w(TRUE YES))
  end

  def import_id
    @import.id
  end
end
