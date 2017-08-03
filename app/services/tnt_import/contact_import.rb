class TntImport::ContactImport
  include Concerns::TntImport::DateHelpers

  def initialize(import, tags, donor_accounts)
    @import = import
    @account_list = import.account_list
    @user = import.user
    @tags = tags
    @donor_accounts = donor_accounts || []
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
      @account_list.contacts.where(name: row['FileAs']).first_or_create
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

    if true?(row['IsOrganization'])
      @donor_accounts.each { |donor_account| add_or_update_company(row, donor_account) }
    end

    contact
  end

  private

  def update_contact(contact, row)
    update_contact_basic_fields(contact, row)
    update_contact_pledge_fields(contact, row)
    update_contact_date_fields(contact, row)

    if (@override || contact.send_newsletter.blank?) && true?(row['SendNewsletter'])
      case row['NewsletterMediaPref']
      when '+E', '+E-P'
        contact.send_newsletter = 'Email'
      when '+P', '+P-E'
        contact.send_newsletter = 'Physical'
      else
        contact.send_newsletter = 'Both'
      end
    end

    @tags.each { |tag| contact.tag_list.add(tag) }

    Retryable.retryable do
      contact.save
    end
  end

  def update_contact_basic_fields(contact, row)
    contact.name = row['FileAs'] if @override || contact.name.blank?
    contact.full_name = row['FullName'] if @override || contact.full_name.blank?
    contact.greeting = row['Greeting'] if @override || contact.greeting.blank?
    contact.envelope_greeting = extract_envelope_greeting_from_row(row) if @override || contact.envelope_greeting.blank?
    contact.website = row['WebPage'] if @override || contact.website.blank?
    contact.church_name = row['ChurchName'] if @override || contact.church_name.blank?
    contact.updated_at = parse_date(row['LastEdit'], @import.user) if @override
    contact.created_at = parse_date(row['CreatedDate'], @import.user) if @override

    add_notes(contact, row)

    contact.direct_deposit = true?(row['DirectDeposit']) if @override || contact.direct_deposit.nil?
    contact.magazine = true?(row['Magazine']) if @override || contact.magazine.nil?
    contact.tnt_id = row['id']
    contact.addresses_attributes =
      TntImport::AddressesBuilder.build_address_array(row, contact, @override)
    contact.is_organization = true?(row['IsOrganization']) if @override || contact.is_organization.nil?
  end

  def update_contact_pledge_fields(contact, row)
    contact.pledge_amount = row['PledgeAmount'] if @override || contact.pledge_amount.blank?
    # PledgeFrequencyID: Since TNT 3.2, a negative number indicates a fequency in days. For example: -11 would be a frequency of 11 days. For now we are ignoring negatives.
    contact.pledge_frequency = row['PledgeFrequencyID'] if (@override || contact.pledge_frequency.blank?) && row['PledgeFrequencyID'].to_i > 0
    contact.pledge_received = true?(row['PledgeReceived']) if @override || contact.pledge_received.blank?
    contact.status = TntImport::TntCodes.mpd_phase(row['MPDPhaseID']) if (@override || contact.status.blank?) && TntImport::TntCodes.mpd_phase(row['MPDPhaseID']).present?
    contact.likely_to_give = contact.assignable_likely_to_gives[row['LikelyToGiveID'].to_i - 1] if (@override || contact.likely_to_give.blank?) && row['LikelyToGiveID'].to_i != 0
    contact.no_appeals = true?(row['NeverAsk']) if @override || contact.no_appeals.nil?
    contact.estimated_annual_pledge_amount = row['EstimatedAnnualCapacity'] if @override || contact.estimated_annual_pledge_amount.nil?
    contact.next_ask_amount = row['NextAskAmount'] if @override || contact.next_ask_amount.nil?
  end

  def update_contact_date_fields(contact, row)
    contact.pledge_start_date = parse_date(row['PledgeStartDate'], @import.user) if (@override || contact.pledge_start_date.blank?) && row['PledgeStartDate'].present? &&
                                                                                    row['PledgeStartDate'] != '1899-12-30'
    contact.next_ask = parse_date(row['NextAsk'], @import.user) if (@override || contact.next_ask.blank?) && row['NextAsk'].present? && row['NextAsk'] != '1899-12-30'
    contact.last_activity = parse_date(row['LastActivity'], @import.user) if (@override || contact.last_activity.blank?) && row['LastActivity'].present? && row['LastActivity'] != '1899-12-30'
    contact.last_appointment = parse_date(row['LastAppointment'], @import.user) if (@override || contact.last_appointment.blank?) && row['LastAppointment'].present? &&
                                                                                   row['LastAppointment'] != '1899-12-30'
    contact.last_letter = parse_date(row['LastLetter'], @import.user) if (@override || contact.last_letter.blank?) && row['LastLetter'].present? && row['LastLetter'] != '1899-12-30'
    contact.last_phone_call = parse_date(row['LastCall'], @import.user) if (@override || contact.last_phone_call.blank?) && row['LastCall'].present? && row['LastCall'] != '1899-12-30'
    contact.last_pre_call = parse_date(row['LastPreCall'], @import.user) if (@override || contact.last_pre_call.blank?) && row['LastPreCall'].present? && row['LastPreCall'] != '1899-12-30'
    contact.last_thank = parse_date(row['LastThank'], @import.user) if (@override || contact.last_thank.blank?) && row['LastThank'].present? && row['LastThank'] != '1899-12-30'
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
    donor_account.update_attribute(:master_company_id, company.master_company_id) unless donor_account.master_company_id == company.master_company.id
    company
  end

  def add_notes(contact, row)
    contact.add_to_notes(row['Notes'])
    contact.add_to_notes("Children: #{row['Children']}") if must_add_children?(row, contact)

    # These social fields don't have equivalents in MPDX, so we'll add them to notes:

    contact.add_to_notes("Other Social: #{row['SocialWeb4']}") if row['SocialWeb4']
    contact.add_to_notes("Spouse Other Social: #{row['SpouseSocialWeb4']}") if row['SpouseSocialWeb4']

    contact.add_to_notes("Voice/Skype: #{row['VoiceSkype']}") if row['VoiceSkype']
    contact.add_to_notes("Spouse Voice/Skype: #{row['SpouseVoiceSkype']}") if row['SpouseVoiceSkype']

    contact.add_to_notes("IM Address: #{row['IMAddress']}") if row['IMAddress']
    contact.add_to_notes("Spouse IM Address: #{row['SpouseIMAddress']}") if row['SpouseIMAddress']
  end

  def extract_envelope_greeting_from_row(row)
    # TNT has something called a "MailingAddressBlock", the envelope greeting is the first line of this string.
    block = row['MailingAddressBlock']
    envelope_greeting = block&.split("\n")&.detect(&:present?) # Find the first non-blank line of the string.
    envelope_greeting.presence || row['FullName']
  end

  def true?(val)
    val.to_s.casecmp('TRUE').zero?
  end

  def must_add_children?(row, contact)
    row['Children'].present? && (!contact.notes || !contact.notes.include?(row['Children']))
  end
end
