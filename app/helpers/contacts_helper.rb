module ContactsHelper
  def spreadsheet_header_titles
    [_('Contact Name'), _('First Name'), _('Last Name'), _('Spouse First Name'), _('Greeting'), _('Envelope Greeting'),
     _('Mailing Street Address'), _('Mailing City'), _('Mailing State'), _('Mailing Postal Code'), _('Mailing Country'), _('Status'),
     _('Commitment Amount'), _('Commitment Currency'), _('Commitment Frequency'), _('Newsletter'), _('Commitment Received'), _('Tags')] +
      (@csv_primary_emails_only ? [_('Primary Email'), _('Spouse Email')] : [_('Email 1'), _('Email 2'), _('Email 3'), _('Email 4')]) +
      [_('Phone 1'), _('Phone 2'), _('Phone 3'), _('Phone 4')]
  end

  def spreadsheet_values(contact)
    row = preliminary_values(contact)
    add_email_addresses(contact, row)
    add_phone_numbers(contact, row)
  end

  def type_array
    Array.new(spreadsheet_header_titles.count, :string)
  end

  private

  def preliminary_values(contact)
    row = []
    row << contact.name
    row << contact.first_name
    row << contact.last_name
    row << contact.spouse_first_name
    row << contact.greeting
    row << contact.envelope_greeting
    row << contact.mailing_address.csv_street
    row << contact.mailing_address.city
    row << contact.mailing_address.state
    row << contact.mailing_address.postal_code
    row << contact.mailing_address.csv_country(contact.account_list.home_country)
    row << contact.status
    row << contact.pledge_amount
    row << contact.pledge_currency
    row << Contact.pledge_frequencies[contact.pledge_frequency || 1.0]
    row << contact.send_newsletter
    row << (contact.pledge_received ? 'Yes' : 'No')
    row << contact.tag_list
    row
  end

  def add_email_addresses(contact, row)
    if @csv_primary_emails_only
      row << contact.try(:primary_person).try(:primary_email_address)
      row << contact.try(:spouse).try(:primary_email_address)
    else
      email_addresses = contact.people.where(optout_enewsletter: false).collect(&:email_addresses).flatten[0..3]
      email_row = 0
      email_addresses.each do |email|
        next if email.historic?
        row << email.email
        email_row += 1
      end
      (email_row..3).each do
        row << ''
      end
    end
    row
  end

  def add_phone_numbers(contact, row)
    phone_numbers = contact.people.collect(&:phone_numbers).flatten[0..3]
    phone_numbers.each do |phone|
      next if phone.historic?
      row << phone.number.to_s
    end
    row
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
