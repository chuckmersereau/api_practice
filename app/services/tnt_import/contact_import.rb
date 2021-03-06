class TntImport::ContactImport
  include Concerns::TntImport::DateHelpers
  include LocalizationHelper

  BEGINNING_OF_TIME = '1899-12-30'.freeze

  def initialize(import, tags, donor_accounts, xml)
    @import = import
    @account_list = import.account_list
    @user = import.user
    @tags = tags
    @donor_accounts = donor_accounts || []
    @xml = xml
    @override = import.override?
  end

  def import_contact(row)
    contact = Retryable.retryable do
      @account_list.contacts.find_by(tnt_id: row['id'])
    end

    @donor_accounts.each do |donor_account|
      contact = donor_account.link_to_contact_for(@account_list, contact)
    end

    # Look for more ways to link a contact
    contact ||= Retryable.retryable do
      @account_list.contacts.where(name: row['FileAs']).first_or_initialize
    end

    # add additional data to contact
    update_contact(contact, row)

    primary_contact_person = add_or_update_primary_person(row, contact)

    # Now the secondary person (persumably spouse)
    if row['SpouseFirstName'].present?
      row['SpouseLastName'] = row['LastName'] if row['SpouseLastName'].blank?
      contact_spouse = add_or_update_spouse(row, contact)

      # Wed the two peple
      primary_contact_person.add_spouse(contact_spouse)
    end

    merge_dups_by_donor_accts(contact, @donor_accounts)

    @donor_accounts.each { |donor_account| add_or_update_company(row, donor_account) } if true?(row['IsOrganization'])

    contact
  end

  private

  def update_contact(contact, row)
    update_contact_basic_fields(contact, row)
    update_contact_pledge_fields(contact, row)
    update_contact_date_fields(contact, row)
    update_contact_send_newsletter_field(contact, row)
    update_locale(contact, row)
    update_contact_tags(contact)

    Retryable.retryable do
      contact.save
    end
  end

  def update_contact_basic_fields(contact, row)
    # we should set value either way if the contact is new because the values are defaulted
    contact.direct_deposit = true?(row['DirectDeposit']) if @override || !contact.persisted?
    contact.magazine = true?(row['Magazine']) if @override || !contact.persisted?
    contact.is_organization = true?(row['IsOrganization']) if @override || !contact.persisted?

    contact.name = row['FileAs'] if @override || contact.name.blank?
    contact.full_name = row['FullName'] if @override || contact.full_name.blank?
    contact.greeting = row['Greeting'] if @override || contact.greeting.blank?
    if @override || contact.attributes['envelope_greeting'].blank?
      contact.envelope_greeting = extract_envelope_greeting_from_row(row)
    end
    contact.website = row['WebPage'] if @override || contact.website.blank?
    contact.church_name = row['ChurchName'] if @override || contact.church_name.blank?
    contact.updated_at = parse_date(row['LastEdit'], @import.user) if @override
    contact.created_at = parse_date(row['CreatedDate'], @import.user) if @override

    add_notes(contact, row)

    contact.tnt_id = row['id']
    contact.addresses.build(TntImport::AddressesBuilder.build_address_array(row, contact, @override))
  end

  def update_contact_pledge_fields(contact, row)
    contact.pledge_amount = row['PledgeAmount'] if @override || contact.pledge_amount.blank?
    # PledgeFrequencyID: Since TNT 3.2, a negative number indicates a fequency in days.
    # For example: -11 would be a frequency of 11 days. For now we are ignoring negatives.
    if (@override || contact.pledge_frequency.blank?) && row['PledgeFrequencyID'].to_i.positive?
      contact.pledge_frequency = row['PledgeFrequencyID']
    end
    contact.pledge_received = true?(row['PledgeReceived']) if @override || contact.pledge_received.blank?
    if (@override || contact.status.blank?) && TntImport::TntCodes.mpd_phase(row['MPDPhaseID']).present?
      contact.status = TntImport::TntCodes.mpd_phase(row['MPDPhaseID'])
    end
    if (@override || contact.likely_to_give.blank?) && row['LikelyToGiveID'].to_i.nonzero?
      contact.likely_to_give = contact.assignable_likely_to_gives[row['LikelyToGiveID'].to_i - 1]
    end
    contact.no_appeals = true?(row['NeverAsk']) if @override || contact.no_appeals.nil?
    if @override || contact.estimated_annual_pledge_amount.nil?
      contact.estimated_annual_pledge_amount = row['EstimatedAnnualCapacity']
    end
    contact.next_ask_amount = row['NextAskAmount'] if @override || contact.next_ask_amount.nil?
    contact.pledge_currency = pledge_currency(row) if @override || contact.pledge_currency.nil?
  end

  def update_contact_date_fields(contact, row)
    if (@override || contact.pledge_start_date.blank?) &&
       row['PledgeStartDate'].present? &&
       row['PledgeStartDate'] != BEGINNING_OF_TIME
      contact.pledge_start_date = parse_date(row['PledgeStartDate'], @import.user)
    end
    if (@override || contact.next_ask.blank?) && row['NextAsk'].present? && row['NextAsk'] != BEGINNING_OF_TIME
      contact.next_ask = parse_date(row['NextAsk'], @import.user)
    end
    if (@override || contact.last_activity.blank?) &&
       row['LastActivity'].present? &&
       row['LastActivity'] != BEGINNING_OF_TIME
      contact.last_activity = parse_date(row['LastActivity'], @import.user)
    end
    if (@override || contact.last_appointment.blank?) &&
       row['LastAppointment'].present? &&
       row['LastAppointment'] != BEGINNING_OF_TIME
      contact.last_appointment = parse_date(row['LastAppointment'], @import.user)
    end
    if (@override || contact.last_letter.blank?) && row['LastLetter'].present? && row['LastLetter'] != BEGINNING_OF_TIME
      contact.last_letter = parse_date(row['LastLetter'], @import.user)
    end
    if (@override || contact.last_phone_call.blank?) && row['LastCall'].present? && row['LastCall'] != BEGINNING_OF_TIME
      contact.last_phone_call = parse_date(row['LastCall'], @import.user)
    end
    if (@override || contact.last_pre_call.blank?) &&
       row['LastPreCall'].present? &&
       row['LastPreCall'] != BEGINNING_OF_TIME
      contact.last_pre_call = parse_date(row['LastPreCall'], @import.user)
    end
    if (@override || contact.last_thank.blank?) && row['LastThank'].present? && row['LastThank'] != BEGINNING_OF_TIME
      contact.last_thank = parse_date(row['LastThank'], @import.user)
    end
  end

  def update_contact_send_newsletter_field(contact, row)
    return unless contact.send_newsletter.nil? || @override

    if true?(row['SendNewsletter'])
      case row['NewsletterMediaPref']
      when '+E', '+E-P'
        contact.send_newsletter = 'Email'
      when '+P', '+P-E'
        contact.send_newsletter = 'Physical'
      else
        contact.send_newsletter = 'Both'
      end
    else
      contact.send_newsletter = 'None'
    end
  end

  def update_locale(contact, row)
    newsletter_lang = @xml.find('NewsletterLang', row['NewsletterLangID']).try(:[], 'Description')
    locale = supported_locales.key(newsletter_lang)
    if locale
      contact.locale = locale
    elsif newsletter_lang.present? && newsletter_lang != 'Unknown'
      contact.tag_list.add(newsletter_lang)
    end
  end

  def update_contact_tags(contact)
    @tags.each do |tag|
      # we replace , with ; to allow for safe tags to be created
      safe_tag = tag.gsub(ActsAsTaggableOn.delimiter, ';')
      contact.tag_list.add(safe_tag)
    end
  end

  def add_or_update_primary_person(row, contact)
    add_or_update_person(row, contact, '')
  end

  def add_or_update_spouse(row, contact)
    add_or_update_person(row, contact, 'Spouse')
  end

  def add_or_update_person(row, contact, prefix)
    TntImport::PersonImport.new(row, contact, prefix, @override).import
  end

  # If the user had two donor accounts in the same contact in Tnt, then  merge different contacts with those in MPDX.
  def merge_dups_by_donor_accts(tnt_contact, donor_accounts)
    dups_by_donor_accts = @account_list.contacts.where.not(id: tnt_contact.id).joins(:donor_accounts)
                                       .where(donor_accounts: { id: donor_accounts.map(&:id) }).readonly(false)

    dups_by_donor_accts.each do |dup_contact_matching_donor_account|
      tnt_contact.merge(dup_contact_matching_donor_account)
    end
  end

  def add_or_update_company(row, donor_account)
    master_company = MasterCompany.find_by(name: row['OrganizationName'])
    company = @user.partner_companies.find_by(master_company_id: master_company.id) if master_company

    company ||= @account_list.companies.new(master_company: master_company)
    company.assign_attributes(name: row['OrganizationName'],
                              phone_number: row['Phone'],
                              street: row['MailingStreetAddress'],
                              city: row['MailingCity'],
                              state: row['MailingState'],
                              postal_code: row['MailingPostalCode'],
                              country: row['MailingCountry'])
    company.save!
    unless donor_account.master_company_id == company.master_company.id
      donor_account.update_attribute(:master_company_id, company.master_company_id)
    end
    company
  end

  def add_notes(contact, row)
    contact.add_to_notes(row['Notes'])

    # These fields don't have equivalents in MPDX, so we'll add them to notes:

    contact.add_to_notes("Children: #{row['Children']}") if row['Children'].present?
    contact.add_to_notes("User Status: #{row['UserStatus']}") if row['UserStatus'].present?
    contact.add_to_notes("Categories: #{row['Categories']}") if row['Categories'].present?

    contact.add_to_notes("Other Social: #{row['SocialWeb4']}") if row['SocialWeb4'].present?
    contact.add_to_notes("Spouse Other Social: #{row['SpouseSocialWeb4']}") if row['SpouseSocialWeb4'].present?

    contact.add_to_notes("Voice/Skype: #{row['VoiceSkype']}") if row['VoiceSkype'].present?
    contact.add_to_notes("Spouse Voice/Skype: #{row['SpouseVoiceSkype']}") if row['SpouseVoiceSkype'].present?

    contact.add_to_notes("IM Address: #{row['IMAddress']}") if row['IMAddress'].present?
    contact.add_to_notes("Spouse IM Address: #{row['SpouseIMAddress']}") if row['SpouseIMAddress'].present?

    contact.add_to_notes("Interests: #{row['Interests']}") if row['Interests'].present?
    contact.add_to_notes("Spouse Interests: #{row['SpouseInterests']}") if row['SpouseInterests'].present?

    contact.add_to_notes("Nickname: #{row['Nickname']}") if row['Nickname'].present?
    contact.add_to_notes("Spouse Nickname: #{row['SpouseNickname']}") if row['SpouseNickname'].present?
  end

  def extract_envelope_greeting_from_row(row)
    # TNT has something called a "MailingAddressBlock", the envelope greeting is the first line of this string.
    block = row['MailingAddressBlock']
    envelope_greeting = block&.split("\n")&.detect(&:present?) # Find the first non-blank line of the string.
    envelope_greeting.presence || row['FullName']
  end

  def pledge_currency(row)
    currency_id = row['PledgeCurrencyID']
    return unless currency_id
    @xml.find('Currency', currency_id).try(:[], 'Code')
  end

  def true?(val)
    val.to_s.casecmp('TRUE').zero?
  end
end
