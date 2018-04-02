module ContactsHelper
  PLEDGE_AMOUNT_INDEX = 12

  def spreadsheet_header_titles
    [_('Contact Name'), _('First Name'), _('Last Name'), _('Spouse First Name'), _('Greeting'),
     _('Envelope Greeting'), _('Mailing Street Address'), _('Mailing City'), _('Mailing State'),
     _('Mailing Postal Code'), _('Mailing Country'), _('Status'), _('Commitment Amount'),
     _('Commitment Currency'), _('Commitment Frequency'), _('Newsletter'), _('Commitment Received'),
     _('Tags'), _('Primary Email'), _('Spouse Email'), _('Other Email'), _('Spouse Other Email'),
     _('Primary Phone'), _('Spouse Phone'), _('Other Phone'), _('Spouse Other Phone')]
  end

  def spreadsheet_header_titles_joined
    spreadsheet_header_titles.map { |h| _(h) }.join('","')
  end

  def spreadsheet_values(contact)
    @contact = contact
    @row = []
    return @row unless @contact

    @primary_person, @spouse = [@contact.primary_person, @contact.spouse].reject { |person| person&.deceased? }

    if @primary_person
      add_preliminary_values_to_row
      add_email_addresses_to_row
      add_phone_numbers_to_row
    end
    @row
  end

  def type_array
    a = Array.new(spreadsheet_header_titles.count, :string)
    # Commitment Amount is a number
    a[PLEDGE_AMOUNT_INDEX] = :float
    a
  end

  private

  def add_preliminary_values_to_row
    @row << @contact.name
    @row << @primary_person.first_name
    @row << @primary_person.last_name
    @row << @spouse&.first_name
    @row << @contact.greeting
    @row << @contact.envelope_greeting
    @row << @contact.mailing_address.csv_street
    @row << @contact.mailing_address.city
    @row << @contact.mailing_address.state
    @row << @contact.mailing_address.postal_code
    @row << @contact.mailing_address.csv_country(@contact.account_list.home_country)
    @row << @contact.status
    @row << @contact.pledge_amount
    @row << @contact.pledge_currency
    @row << Contact.pledge_frequencies[@contact.pledge_frequency || 1.0]
    @row << @contact.send_newsletter
    @row << (@contact.pledge_received ? 'Yes' : 'No')
    @row << @contact.tag_list
  end

  def add_email_addresses_to_row
    @primary_email_address = @primary_person&.primary_email_address
    @spouse_primary_email_address = @spouse&.primary_email_address

    @row << @primary_email_address&.email || ''
    @row << @spouse_primary_email_address&.email || ''

    @other_relevant_email_addresses = fetch_other_relevant_email_addresses

    @row << find_email_address_by_person_id(@primary_person&.id)&.email || ''
    @row << find_email_address_by_person_id(@spouse&.id)&.email || ''
  end

  def add_phone_numbers_to_row
    @primary_phone_number = @primary_person&.primary_phone_number
    @spouse_primary_phone_number = @spouse&.primary_phone_number

    @row << @primary_phone_number&.number || ''
    @row << @spouse_primary_phone_number&.number || ''

    @other_relevant_phone_numbers = fetch_other_relevant_phone_numbers

    @row << find_phone_number_by_person_id(@primary_person&.id)&.number || ''
    @row << find_phone_number_by_person_id(@spouse&.id)&.number || ''
  end

  def find_email_address_by_person_id(person_id)
    return unless person_id

    @other_relevant_email_addresses.find do |email_address|
      email_address.person_id == person_id
    end
  end

  def find_phone_number_by_person_id(person_id)
    return unless person_id

    @other_relevant_phone_numbers.find do |phone_number|
      phone_number.person_id == person_id
    end
  end

  def fetch_other_relevant_email_addresses
    @contact.people
            .alive
            .map(&:email_addresses)
            .flatten
            .compact
            .select do |email_address|
      ids = [@primary_email_address&.id, @spouse_primary_email_address&.id]
      ids.exclude?(email_address.id) && email_address.historic == false
    end
  end

  def fetch_other_relevant_phone_numbers
    @contact.people
            .alive
            .map(&:phone_numbers)
            .flatten
            .compact
            .select do |phone_number|
      ids = [@primary_phone_number&.id, @spouse_primary_phone_number&.id]
      ids.exclude?(phone_number.id) && phone_number.historic == false
    end
  end

  def contact_locale_filter_options(account_list)
    options = account_list.contact_locales.select(&:present?).map do |locale|
      [_(MailChimpAccount::Locales::LOCALE_NAMES[locale]), locale]
    end

    options_for_select(
      [[_('-- Any --'), ''], [_('-- Unspecified --'), 'null']] +
      options
    )
  end
end
