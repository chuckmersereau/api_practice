class TntImport::ContactImport
  def initialize(import, tags, donor_accounts)
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

  def update_contact(contact, row)
    update_contact_basic_fields(contact, row)
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

    contact.save
  end

  def update_contact_basic_fields(contact, row)
    contact.name = row['FileAs'] if @override || contact.name.blank?
    contact.full_name = row['FullName'] if @override || contact.full_name.blank?
    contact.greeting = row['Greeting'] if @override || contact.greeting.blank?
    contact.website = row['WebPage'] if @override || contact.website.blank?
    contact.updated_at = parse_date(row['LastEdit']) if @override
    contact.created_at = parse_date(row['CreatedDate']) if @override
    contact.notes = row['Notes'] if @override || contact.notes.blank?
    contact.pledge_amount = row['PledgeAmount'] if @override || contact.pledge_amount.blank?
    contact.pledge_frequency = row['PledgeFrequencyID'] if (@override || contact.pledge_frequency.blank?) && row['PledgeFrequencyID'].to_i != 0
    contact.pledge_received = true?(row['PledgeReceived']) if @override || contact.pledge_received.blank?
    contact.status = TntImport::TntCodes.mpd_phase(row['MPDPhaseID']) if (@override || contact.status.blank?) && TntImport::TntCodes.mpd_phase(row['MPDPhaseID']).present?
    contact.likely_to_give = contact.assignable_likely_to_gives[row['LikelyToGiveID'].to_i - 1] if (@override || contact.likely_to_give.blank?) && row['LikelyToGiveID'].to_i != 0
    contact.no_appeals = true?(row['NeverAsk']) if @override || contact.no_appeals.blank?
    contact.church_name = row['ChurchName'] if @override || contact.church_name.blank?

    contact.direct_deposit = true?(row['DirectDeposit']) if @override || contact.direct_deposit.blank?
    contact.magazine = true?(row['Magazine']) if @override || contact.magazine.blank?
    contact.tnt_id = row['id']
    contact.addresses_attributes =
      TntImport::AddressesBuilder.build_address_array(row, contact, @override)
  end

  def update_contact_date_fields(contact, row)
    contact.pledge_start_date = parse_date(row['PledgeStartDate']) if (@override || contact.pledge_start_date.blank?) && row['PledgeStartDate'].present? &&
                                                                      row['PledgeStartDate'] != '1899-12-30'
    contact.next_ask = parse_date(row['NextAsk']) if (@override || contact.next_ask.blank?) && row['NextAsk'].present? && row['NextAsk'] != '1899-12-30'
    contact.last_activity = parse_date(row['LastActivity']) if (@override || contact.last_activity.blank?) && row['LastActivity'].present? && row['LastActivity'] != '1899-12-30'
    contact.last_appointment = parse_date(row['LastAppointment']) if (@override || contact.last_appointment.blank?) && row['LastAppointment'].present? &&
                                                                     row['LastAppointment'] != '1899-12-30'
    contact.last_letter = parse_date(row['LastLetter']) if (@override || contact.last_letter.blank?) && row['LastLetter'].present? && row['LastLetter'] != '1899-12-30'
    contact.last_phone_call = parse_date(row['LastCall']) if (@override || contact.last_phone_call.blank?) && row['LastCall'].present? && row['LastCall'] != '1899-12-30'
    contact.last_pre_call = parse_date(row['LastPreCall']) if (@override || contact.last_pre_call.blank?) && row['LastPreCall'].present? && row['LastPreCall'] != '1899-12-30'
    contact.last_thank = parse_date(row['LastThank']) if (@override || contact.last_thank.blank?) && row['LastThank'].present? && row['LastThank'] != '1899-12-30'
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
      tnt_contact.reload.merge(dup_contact_matching_donor_account)
    end
  end

  def add_or_update_company(row, donor_account)
    master_company = MasterCompany.find_by_name(row['OrganizationName'])
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

  def true?(val)
    val.casecmp('TRUE').zero?
  end

  def parse_date(val)
    Date.parse(val)
  rescue
  end
end
