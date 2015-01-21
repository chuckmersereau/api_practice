class TntImport
  include TntImportUtil

  # Donation Services seems to pad donor accounts with zeros up to length 9. TntMPD does not though.
  DONOR_NUMBER_NORMAL_LEN = 9

  def initialize(import)
    @import = import
    @account_list = @import.account_list
    @user = @import.user
    @designation_profile = @account_list.designation_profiles.first || @user.designation_profiles.first
    @tags_by_contact_id = {}
  end

  def xml
    unless @xml
      @xml = read_xml(@import.file.file.file)
      if @xml.present? && @xml['Database']
        @xml = @xml['Database']['Tables']
      else
        @xml = nil
      end
    end
    @xml
  end

  def import
    @import.file.cache_stored_file!
    return unless xml.present?

    tnt_contacts = import_contacts
    import_tasks(tnt_contacts)
    import_history(tnt_contacts)
    import_offline_org_gifts(tnt_contacts)
    import_settings
  ensure
    CarrierWave.clean_cached_files!
  end

  private

  def import_contacts
    load_contact_group_tags

    rows = Array.wrap(xml['Contact']['row'])
    @tnt_contacts = {}
    rows.each { |row| @tnt_contacts[row['id']] = import_contact(row) }

    import_referrals(rows)

    @tnt_contacts
  end

  def load_contact_group_tags
    @tags_by_contact_id = {}

    return unless xml['Group']

    groups = Array.wrap(xml['Group']['row']).map do |row|
      { id: row['id'], category: row['Category'],
        description: row['Category'] ? row['Description'].sub("#{row['Category']}\\", '') : row['Description'] }
    end
    groups_by_id = Hash[groups.map { |group| [group[:id], group] }]

    Array.wrap(xml['GroupContact']['row']).each do |row|
      group = groups_by_id[row['GroupID']]
      tags = [group[:description].gsub(' ', '-')]
      tags << group[:category].gsub(' ', '-') if group[:category]

      tags_list = @tags_by_contact_id[row['ContactID']]
      tags_list ||= []
      tags_list += tags
      @tags_by_contact_id[row['ContactID']] = tags_list
    end
  end

  def import_contact(row)
    contact = Retryable.retryable do
      @account_list.contacts.where(tnt_id: row['id']).first
    end

    donor_accounts = add_or_update_donor_accounts(row, @designation_profile)

    donor_accounts.each do |donor_account|
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

    merge_dups_by_donor_accts(contact, donor_accounts)

    if true?(row['IsOrganization'])
      donor_accounts.each { |donor_account|  add_or_update_company(row, donor_account) }
    end

    contact
  end

  def import_referrals(rows)
    # Loop over the whole list again now that we've added everyone and try to link up referrals
    rows.each do |row|
      referred_by = @tnt_contacts.find { |_tnt_id, c|
        c.name == row['ReferredBy'] || c.full_name == row['ReferredBy'] || c.greeting == row['ReferredBy']
      }
      next unless referred_by
      contact = @tnt_contacts[row['id']]
      contact.referrals_to_me << referred_by[1] unless contact.referrals_to_me.include?(referred_by[1])
    end
  end

  # If the user had two donor accounts in the same contact in Tnt, then  merge different contacts with those in MPDX.
  def merge_dups_by_donor_accts(tnt_contact, donor_accounts)
    dups_by_donor_accts = @account_list.contacts.where.not(id: tnt_contact.id).joins(:donor_accounts)
      .where(donor_accounts: { id: donor_accounts.map(&:id) }).readonly(false)

    dups_by_donor_accts.each do |dup_contact_matching_donor_account|
      tnt_contact.reload.merge(dup_contact_matching_donor_account)
    end
  end

  def import_tasks(tnt_contacts = {})
    tnt_tasks = {}

    Array.wrap(xml['Task']['row']).each do |row|
      task = Retryable.retryable do
        @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize
      end

      task.attributes = {
        activity_type: lookup_task_type(row['TaskTypeID']),
        subject: row['Description'],
        start_at: DateTime.parse(row['TaskDate'] + ' ' + DateTime.parse(row['TaskTime']).strftime('%I:%M%p'))
      }
      next unless task.save
      # Add any notes as a comment
      task.activity_comments.create(body: row['Notes'].strip) if row['Notes'].present?
      tnt_tasks[row['id']] = task
    end

    # Add contacts to tasks
    Array.wrap(xml['TaskContact']['row']).each do |row|
      next unless tnt_contacts[row['ContactID']] && tnt_tasks[row['TaskID']]
      tnt_tasks[row['TaskID']].contacts << tnt_contacts[row['ContactID']] unless tnt_tasks[row['TaskID']].contacts.include? tnt_contacts[row['ContactID']]
    end

    tnt_tasks
  end

  def import_history(tnt_contacts = {})
    tnt_history = {}

    Array.wrap(xml['History']['row']).each do |row|
      task = Retryable.retryable do
        @account_list.tasks.where(remote_id: row['id'], source: 'tnt').first_or_initialize
      end

      task.attributes = {
        activity_type: lookup_task_type(row['TaskTypeID']),
        subject: row['Description'] || lookup_task_type(row['TaskTypeID']),
        start_at: DateTime.parse(row['HistoryDate']),
        completed_at: DateTime.parse(row['HistoryDate']),
        completed: true,
        result: lookup_history_result(row['HistoryResultID'])
      }
      next unless task.save
      # Add any notes as a comment
      task.activity_comments.create(body: row['Notes'].strip) if row['Notes'].present?
      tnt_history[row['id']] = task
    end

    # Add contacts to tasks
    Array.wrap(xml['HistoryContact']['row']).each do |row|
      next unless tnt_contacts[row['ContactID']] && tnt_history[row['HistoryID']]
      Retryable.retryable times: 3, sleep: 1 do
        tnt_history[row['HistoryID']].contacts << tnt_contacts[row['ContactID']] unless tnt_history[row['HistoryID']].contacts.include? tnt_contacts[row['ContactID']]
      end
    end

    tnt_history
  end

  def import_offline_org_gifts(tnt_contacts)
    return unless @account_list.organization_accounts.count == 1
    org = @account_list.organization_accounts.first.organization
    return unless org.api_class == 'OfflineOrg'

    Array.wrap(xml['Gift']['row']).each do |row|
      contact = tnt_contacts[row['ContactID']]
      next unless contact
      account = donor_account_for_contact(org, contact)

      # If someone re-imports donations, assume that there is just one donation per date per amount;
      # that's not a perfect assumption but it seems reasonable solution for offline orgs for now.
      donation_key_attrs = {  amount: row['Amount'], donation_date: parse_date(row['GiftDate']) }
      account.donations.find_or_create_by(donation_key_attrs) do |donation|
        # Assume the currency is USD. Tnt doesn't have great currency support and USD is a decent default.
        donation.update(tendered_currency: 'USD', tendered_amount: row['Amount'])

        contact.update_donation_totals(donation)
      end
    end
  end

  def donor_account_for_contact(org, contact)
    account = contact.donor_accounts.first
    return account if account

    donor_account = Retryable.retryable(sleep: 60, tries: 3) do
      # Find a unique donor account_number for this contact. Try the current max numeric account number
      # plus one. If that is a collision due to a race condition, an exception will be raised as there is a
      # unique constraint on (organization_id, account_number) for donor_accounts. Just wait and try
      # again in that case.
      max = org.donor_accounts.where("account_number ~ '^[0-9]+$'").maximum('CAST(account_number AS int)')
      org.donor_accounts.create!(account_number: (max.to_i + 1).to_s, name: contact.name)
    end
    contact.donor_accounts << donor_account
    donor_account
  end

  def import_settings
    Array.wrap(xml['Property']['row']).each do |row|
      case row['PropName']
      when 'MonthlySupportGoal'
        @account_list.monthly_goal = row['PropValue'] if @import.override? || @account_list.monthly_goal.blank?
      when 'MailChimpListId'
        @mail_chimp_list_id = row['PropValue']
      when 'MailChimpAPIKey'
        @mail_chimp_key = row['PropValue']
      end

      create_or_update_mailchimp(@mail_chimp_list_id, @mail_chimp_key) if @mail_chimp_list_id && @mail_chimp_key
    end
    @account_list.save
  end

  def create_or_update_mailchimp(mail_chimp_list_id, mail_chimp_key)
    if @account_list.mail_chimp_account
      if @import.override?
        @account_list.mail_chimp_account.update_attributes(api_key: mail_chimp_key,
                                                           primary_list_id: mail_chimp_list_id)
      end
    else
      @account_list.create_mail_chimp_account(api_key: mail_chimp_key,
                                              primary_list_id: mail_chimp_list_id)
    end
  end

  def update_contact(contact, row)
    update_contact_basic_fields(contact, row)

    if (@import.override? || contact.send_newsletter.blank?) && true?(row['SendNewsletter'])
      case row['NewsletterMediaPref']
      when '+E', '+E-P'
        contact.send_newsletter = 'Email'
      when '+P', '+P-E'
        contact.send_newsletter = 'Physical'
      else
        contact.send_newsletter = 'Both'
      end
    end

    tags = @tags_by_contact_id[row['id']]
    tags.each { |tag| contact.tag_list.add(tag) } if tags

    contact.save
  end

  def update_contact_basic_fields(contact, row)
    contact.name = row['FileAs'] if @import.override? || contact.name.blank?
    contact.full_name = row['FullName'] if @import.override? || contact.full_name.blank?
    contact.greeting = row['Greeting'] if @import.override? || contact.greeting.blank?
    contact.website = row['WebPage'] if @import.override? || contact.website.blank?
    contact.updated_at = parse_date(row['LastEdit']) if @import.override?
    contact.created_at = parse_date(row['CreatedDate']) if @import.override?
    contact.notes = row['Notes'] if @import.override? || contact.notes.blank?
    contact.pledge_amount = row['PledgeAmount'] if @import.override? || contact.pledge_amount.blank?
    contact.pledge_frequency = row['PledgeFrequencyID'] if (@import.override? || contact.pledge_frequency.blank?) && row['PledgeFrequencyID'].to_i != 0
    contact.pledge_start_date = parse_date(row['PledgeStartDate']) if (@import.override? || contact.pledge_start_date.blank?) && row['PledgeStartDate'].present?
    contact.pledge_received = true?(row['PledgeReceived']) if @import.override? || contact.pledge_received.blank?
    contact.status = lookup_mpd_phase(row['MPDPhaseID']) if (@import.override? || contact.status.blank?) && lookup_mpd_phase(row['MPDPhaseID']).present?
    contact.next_ask = parse_date(row['NextAsk']) if (@import.override? || contact.next_ask.blank?) && row['NextAsk'].present?
    contact.likely_to_give = contact.assignable_likely_to_gives[row['LikelyToGiveID'].to_i - 1] if (@import.override? || contact.likely_to_give.blank?) && row['LikelyToGiveID'].to_i != 0
    contact.never_ask = true?(row['NeverAsk']) if @import.override? || contact.never_ask.blank?
    contact.church_name = row['ChurchName'] if @import.override? || contact.church_name.blank?

    contact.direct_deposit = true?(row['DirectDeposit']) if @import.override? || contact.direct_deposit.blank?
    contact.magazine = true?(row['Magazine']) if @import.override? || contact.magazine.blank?
    contact.last_activity = parse_date(row['LastActivity']) if (@import.override? || contact.last_activity.blank?) && row['LastActivity'].present?
    contact.last_appointment = parse_date(row['LastAppointment']) if (@import.override? || contact.last_appointment.blank?) && row['LastAppointment'].present?
    contact.last_letter = parse_date(row['LastLetter']) if (@import.override? || contact.last_letter.blank?) && row['LastLetter'].present?
    contact.last_phone_call = parse_date(row['LastCall']) if (@import.override? || contact.last_phone_call.blank?) && row['LastCall'].present?
    contact.last_pre_call = parse_date(row['LastPreCall']) if (@import.override? || contact.last_pre_call.blank?) && row['LastPreCall'].present?
    contact.last_thank = parse_date(row['LastThank']) if (@import.override? || contact.last_thank.blank?) && row['LastThank'].present?
    contact.tag_list.add(@import.tags, parse: true) if @import.tags.present?
    contact.tnt_id = row['id']
    contact.addresses_attributes = build_address_array(row, contact, @import.override)
  end

  def add_or_update_company(row, donor_account)
    master_company = MasterCompany.find_by_name(row['OrganizationName'])
    company = @user.partner_companies.where(master_company_id: master_company.id).first if master_company

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

  def add_or_update_primary_person(row, contact)
    add_or_update_person(row, contact)
  end

  def add_or_update_spouse(row, contact)
    add_or_update_person(row, contact, 'Spouse')
  end

  def add_or_update_person(row, contact, prefix = '')
    row[prefix + 'FirstName'] = 'Unknown' if row[prefix + 'FirstName'].blank?

    # See if there's already a person by this name on this contact (This is a contact with multiple donation accounts)
    person = contact.people.where(first_name: row[prefix + 'FirstName'], last_name: row[prefix + 'LastName'])
                           .where("middle_name = ? OR middle_name = '' OR middle_name is NULL", row[prefix + 'MiddleName']).first
    person ||= Person.new

    update_person_attributes(person, row, prefix)

    person.master_person_id ||= MasterPerson.find_or_create_for_person(person).id

    person.save(validate: false)

    begin
      contact.people << person unless contact.people.include?(person)
    rescue ActiveRecord::RecordNotUnique
    end

    person
  end

  def tnt_phone_locations(prefix)
    locations = { 'HomePhone' => 'home', 'HomePhone2' => 'home', 'HomeFax' => 'fax',
      'OtherPhone' => 'other', 'OtherFax' => 'fax' }

    # Note: The order of these locations is important. The TntMPD export field PreferredPhoneType will
    # index into this ordered hash and correspond with which phone number will get marked as preferred.
    if prefix == 'Spouse'
      locations.merge!(tnt_prefixed_phones('DO_NOT_IMPORT')).merge!(tnt_prefixed_phones(prefix))
    else
      locations.merge!(tnt_prefixed_phones(prefix)).merge!(tnt_prefixed_phones('DO_NOT_IMPORT'))
    end

    # These are old fields that are no longer in the user interface for Tnt 3.0, so put them at the end.
    locations.merge('AssistantPhone' => 'work', 'OtherPhone' => 'other', 'CarPhone' => 'mobile',
                    'CallbackPhone' => 'other', 'ISDNPhone' => 'other', 'PrimaryPhone' => 'other',
                    'RadioPhone' => 'other', 'TelexPhone' => 'other')
  end

  def tnt_prefixed_phones(prefix)
    { prefix + 'MobilePhone' => 'mobile', prefix + 'MobilePhone2' => 'mobile',
      prefix + 'PagerNumber' => 'other', prefix + 'BusinessPhone' => 'work', prefix + 'BusinessPhone2' => 'work',
      prefix + 'BusinessFax' => 'fax',  prefix + 'CompanyMainPhone' => 'work' }
  end

  def update_person_attributes(person, row, prefix = '')
    person.attributes = { first_name: row[prefix + 'FirstName'], last_name: row[prefix + 'LastName'], middle_name: row[prefix + 'MiddleName'],
                          title: row[prefix + 'Title'], suffix: row[prefix + 'Suffix'], gender: prefix.present? ? 'female' : 'male',
                          profession: prefix.present? ? nil : row['Profession'] }

    update_person_phones(person, row, prefix)
    update_person_emails(person, row, prefix)
    person
  end

  def update_person_phones(person, row, prefix)
    found_primary = false
    tnt_phone_locations(prefix).each_with_index do |key, i|
      next unless row[key[0]].present? && row['PhoneIsValidMask'].to_i[i] == 1 # Index mask as bit vector
      phone_attrs =  { number: row[key[0]], location: key[1] }
      if @import.override? && !found_primary && row['PreferredPhoneType'].to_i == i
        phone_attrs[:primary] = true
        person.phone_numbers.each { |phone| phone.update(primary: false) }
        found_primary = true
      end
      person.phone_number =  phone_attrs
    end
  end

  def update_person_emails(person, row, prefix)
    found_primary = false

    # If there is just a single email in Tnt, it leaves the suffix off, so start with a blank then do the numbers
    # up to three as Tnt allows a maximum of 3 email addresses for a person/spouse.
    ['', '1', '2', '3'].each_with_index do |email_suffix, index|
      email = row[prefix + "Email#{email_suffix}"]
      next unless email.present?

      email_valid = row[prefix + 'Email' + email_suffix + 'IsValid']
      historic = email_valid.present? && !true?(email_valid)

      email_attrs = { email: email, historic: historic }

      # For MPDX, we set the primary email to be the first "preferred" email listed in Tnt.
      email_num = email_suffix == '' ? 1 : index
      if @import.override? && !found_primary && !historic && tnt_email_preferred?(row, email_num, prefix)
        person.email_addresses.each { |e| e.update(primary: false) }
        email_attrs[:primary] = true
        found_primary = true
      end

      person.email_address = email_attrs
    end
  end

  # TntMPD allows multiple emails to be marked as preferred and expresses that array of booleans as a
  # bit vector in the PreferredEmailTypes. Bit 0 is ignored, then 3 for primary person emails, then 3 for spouse
  def tnt_email_preferred?(row, email_num, person_prefix)
    preferred_bit_index = (person_prefix == 'Spouse' ? 3 : 0) + email_num
    row['PreferredEmailTypes'].present? && row['PreferredEmailTypes'].to_i[preferred_bit_index] == 1
  end

  def add_or_update_donor_accounts(row, designation_profile)
    # create variables outside the block scope
    donor_accounts = []

    if designation_profile
      donor_accounts = row['OrgDonorCodes'].to_s.split(',').map do |account_number|
        donor_account = Retryable.retryable do
          da = designation_profile.organization.donor_accounts
            .where('account_number = :account_number OR account_number = :padded_account_number',
                   account_number: account_number,
                   padded_account_number: account_number.rjust(DONOR_NUMBER_NORMAL_LEN, '0')).first

          if da
            # Donor accounts for non-Cru orgs could have nil names so update with the name from tnt
            da.update(name: row['FileAs']) if da.name.blank?
          else
            da = designation_profile.organization.donor_accounts.new(account_number: account_number, name: row['FileAs'])
            da.addresses_attributes = build_address_array(row)
            da.save!
          end
          da
        end
        donor_account
      end
    end

    donor_accounts
  end

  def build_address_array(row, contact = nil, override = true)
    addresses = []
    %w(Home Business Other).each_with_index do |location, i|
      street = row["#{location}StreetAddress"]
      city = row["#{location}City"]
      state = row["#{location}State"]
      postal_code = row["#{location}PostalCode"]
      country = row["#{location}Country"] == 'United States of America' ? 'United States' : row["#{location}Country"]
      next unless [street, city, state, postal_code].any?(&:present?)
      primary_address = false
      primary_address = row['MailingAddressType'].to_i == (i + 1) if override
      if primary_address && contact
        contact.addresses.each do |address|
          next if address.street == street && address.city == city && address.state == state && address.postal_code == postal_code && address.country == country
          address.primary_mailing_address = false
          address.save
        end
      end
      addresses << {  street: street,  city: city,  state: state,  postal_code: postal_code,  country: country,
        location: location,  region: row['Region'],  primary_mailing_address: primary_address  }
    end
    addresses
  end
end
