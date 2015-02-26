# rubocop:disable Metrics/ClassLength
class TntImport
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

  def read_xml(import_file)
    xml = {}
    begin
      File.open(import_file, 'r:utf-8') do |file|
        @contents = file.read
        begin
          xml = Hash.from_xml(@contents)
        rescue => e
          # If the document contains characters that we don't know how to parse
          # just strip them out.
          # The eval is dirty, but it was all I could come up with at the time
          # to unescape a unicode character.
          begin
            bad_char = e.message.match(/"([^"]*)"/)[1]
            @contents.gsub!(eval(%("#{bad_char}")), ' ') # rubocop:disable Eval
          rescue
            raise e
          end
          retry
        end
      end
    rescue ArgumentError
      File.open(import_file, 'r:windows-1251:utf-8') do |file|
        xml = Hash.from_xml(file.read)
      end
    end
    xml
  end

  def import
    @import.file.cache_stored_file!
    return unless xml.present?

    tnt_contacts = import_contacts
    import_tasks(tnt_contacts)
    _history, contacts_by_tnt_appeal_id = import_history(tnt_contacts)
    import_offline_org_gifts(tnt_contacts)
    import_settings
    import_appeals(contacts_by_tnt_appeal_id)
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
    return unless xml['Task'].present? && xml['TaskContact'].present?
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

    tnt_history_id_to_appeal_id = {}

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

      tnt_history_id_to_appeal_id[row['id']] = row['AppealID'] if row['AppealID'].present?

      next unless task.save
      # Add any notes as a comment
      task.activity_comments.create(body: row['Notes'].strip) if row['Notes'].present?
      tnt_history[row['id']] = task
    end

    contacts_by_tnt_appeal_id = {}

    # Add contacts to tasks
    Array.wrap(xml['HistoryContact']['row']).each do |row|
      contact = tnt_contacts[row['ContactID']]
      task = tnt_history[row['HistoryID']]
      next unless contact && task

      Retryable.retryable times: 3, sleep: 1 do
        task.contacts << contact unless task.contacts.include?(contact)
      end

      tnt_appeal_id = tnt_history_id_to_appeal_id[row['HistoryID']]
      if tnt_appeal_id
        contacts_by_tnt_appeal_id[tnt_appeal_id] ||= []
        contacts_by_tnt_appeal_id[tnt_appeal_id] << contact
      end
    end

    [tnt_history, contacts_by_tnt_appeal_id]
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

  def import_appeals(contacts_by_tnt_appeal_id)
    appeals_by_tnt_id = find_or_create_appeals_by_tnt_id

    appeals_by_tnt_id.each do |appeal_tnt_id, appeal|
      appeal.bulk_add_contacts(contacts_by_tnt_appeal_id[appeal_tnt_id] || [])
    end

    import_appeal_amounts(appeals_by_tnt_id)
  end

  def find_or_create_appeals_by_tnt_id
    return {} unless xml['Appeal'].present?
    appeals = {}
    Array.wrap(xml['Appeal']['row']).each do |row|
      appeals[row['id']] = @account_list.appeals.find_by(tnt_id: row['id']) ||
        @account_list.appeals.find_or_create_by(name: row['Description']) { |new| new.tnt_id = row['id'].to_i }
    end
    appeals
  end

  def import_appeal_amounts(appeals_by_tnt_id)
    return unless xml['Gift'].present?

    donor_accounts_by_tnt_id = find_donor_accounts_by_tnt_id
    designation_account_ids = @account_list.designation_accounts.pluck(:id)

    Array.wrap(xml['Gift']['row']).each do |row|
      next if row['AppealID'].blank?
      appeal = appeals_by_tnt_id[row['AppealID']]
      donor_account = donor_accounts_by_tnt_id[row['DonorID']]
      next unless donor_account

      donation = donor_account.donations.where(donation_date: row['GiftDate'], amount: row['Amount'])
                   .where(designation_account_id: designation_account_ids)
                   .where('appeal_id is null or appeal_id = ?', appeal.id).first
      next if donation.blank?
      donation.update(appeal: appeal, appeal_amount: row['AppealAmount'])
    end
  end

  def find_donor_accounts_by_tnt_id
    return {} unless xml['Donor'].present?
    donors = {}
    Array.wrap(xml['Donor']['row']).each do |row|
      donors[row['id']] = @account_list.donor_accounts.find_by(account_number: row['OrgDonorCode'])
    end
    donors
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

  def update_person_attributes(person, row, prefix = '')
    person.attributes = { first_name: row[prefix + 'FirstName'], last_name: row[prefix + 'LastName'], middle_name: row[prefix + 'MiddleName'],
                          title: row[prefix + 'Title'], suffix: row[prefix + 'Suffix'], gender: prefix.present? ? 'female' : 'male',
                          profession: prefix.present? ? nil : row['Profession'] }

    update_person_phones(person, row, prefix)
    update_person_emails(person, row, prefix)
    person
  end

  # This is an ordered array of the Tnt phone types. The order matters because the tnt  PreferredPhoneType
  # is an index that into this list and the PhoneIsValidMask is a bit vector that refers to these in order too.
  TNT_PHONES = [
    { field: 'HomePhone', location: 'home', person: :both }, # index 0
    { field: 'HomePhone2', location: 'home', person: :both },
    { field: 'HomeFax', location: 'fax', person: :both },
    { field: 'OtherPhone', location: 'other', person: :both },
    { field: 'OtherFax', location: 'fax', person: :both },

    { field: 'MobilePhone', location: 'mobile', person: :primary },
    { field: 'MobilePhone2', location: 'mobile', person: :primary },
    { field: 'PagerNumber', location: 'other', person: :primary },
    { field: 'BusinessPhone', location: 'work', person: :primary },
    { field: 'BusinessPhone2', location: 'work', person: :primary },
    { field: 'BusinessFax', location: 'fax', person: :primary },
    { field: 'CompanyMainPhone', location: 'work', person: :primary },

    { field: 'SpouseMobilePhone', location: 'mobile', person: :spouse },
    { field: 'SpouseMobilePhone2', location: 'mobile', person: :spouse },
    { field: 'SpousePagerNumber', location: 'other', person: :spouse },
    { field: 'SpouseBusinessPhone', location: 'work', person: :spouse },
    { field: 'SpouseBusinessPhone2', location: 'work', person: :spouse },
    { field: 'SpouseBusinessFax', location: 'fax', person: :spouse },
    { field: 'SpouseCompanyMainPhone', location: 'work', person: :spouse } # index 18
  ]

  def update_person_phones(person, row, prefix)
    person_sym = prefix == '' ? :primary : :spouse
    is_valid_mask = row['PhoneIsValidMask'].to_i # Bit vector indexed corresponding to TNT_PHONES
    had_no_primary = person.phone_numbers.where(primary: true).empty?

    TNT_PHONES.each_with_index do |tnt_phone, i|
      number = row[tnt_phone[:field]]
      next unless number.present? && (tnt_phone[:person] == :both || tnt_phone[:person] == person_sym)

      phone_attrs =  { number: number, location: tnt_phone[:location], historic: is_valid_mask[i] == 0 }
      if (@import.override? || had_no_primary) && row['PreferredPhoneType'].to_i == i
        phone_attrs[:primary] = true
        person.phone_numbers.each { |phone| phone.update(primary: false) }
      end
      person.phone_number =  phone_attrs
    end
  end

  def update_person_emails(person, row, prefix)
    changed_primary = false
    had_no_primary = person.email_addresses.where(primary: true).empty?

    # If there is just a single email in Tnt, it leaves the suffix off, so start with a blank then do the numbers
    # up to three as Tnt allows a maximum of 3 email addresses for a person/spouse.
    (1..3).each do |i|
      email = row[prefix + "Email#{i}"]
      next unless email.present?

      email_valid = row["#{prefix}Email#{i}IsValid"]
      historic = email_valid.present? && !true?(email_valid)

      email_attrs = { email: email, historic: historic }

      # For MPDX, we set the primary email to be the first "preferred" email listed in Tnt.
      if (@import.override? || had_no_primary) && !changed_primary && !historic && tnt_email_preferred?(row, i, prefix)
        person.email_addresses.each { |e| e.update(primary: false) }
        email_attrs[:primary] = true
        changed_primary = true
      end

      person.email_address = email_attrs
    end
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
    contact.no_appeals = true?(row['NeverAsk']) if @import.override? || contact.no_appeals.blank?
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
        location: location,  region: row['Region'],  primary_mailing_address: primary_address,
        source: 'TntImport'  }
    end
    addresses
  end

  def lookup_mpd_phase(phase)
    case phase.to_i
    when 10 then 'Never Contacted'
    when 20 then 'Ask in Future'
    when 30 then 'Contact for Appointment'
    when 40 then 'Appointment Scheduled'
    when 50 then 'Call for Decision'
    when 60 then 'Partner - Financial'
    when 70 then 'Partner - Special'
    when 80 then 'Partner - Pray'
    when 90 then 'Not Interested'
    when 95 then 'Unresponsive'
    when 100 then 'Never Ask'
    when 110 then 'Research Abandoned'
    when 130 then 'Expired Referral'
    end
  end

  def lookup_task_type(task_type_id)
    case task_type_id.to_i
    when 1 then 'Appointment'
    when 2 then 'Thank'
    when 3 then 'To Do'
    when 20 then 'Call'
    when 30 then 'Reminder Letter'
    when 40 then 'Support Letter'
    when 50 then 'Letter'
    when 60 then 'Newsletter'
    when 70 then 'Pre Call Letter'
    when 100 then 'Email'
    end
  end

  def lookup_history_result(history_result_id)
    case history_result_id.to_i
    when 1 then 'Done'
    when 2 then 'Received'
    when 3 then 'Attempted'
    end
  end

  def true?(val)
    val.upcase == 'TRUE'
  end

  def parse_date(val)
    Date.parse(val)
  rescue
  end

  # TntMPD allows multiple emails to be marked as preferred and expresses that array of booleans as a
  # bit vector in the PreferredEmailTypes. Bit 0 is ignored, then 3 for primary person emails, then 3 for spouse
  def tnt_email_preferred?(row, email_num, person_prefix)
    preferred_bit_index = (person_prefix == 'Spouse' ? 3 : 0) + email_num
    row['PreferredEmailTypes'].present? && row['PreferredEmailTypes'].to_i[preferred_bit_index] == 1
  end
end
