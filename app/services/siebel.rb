# This service as been superseded by DonationImports::Siebel.
# It should be deleted when DonationImports::Siebel is stable.

require_dependency 'data_server'
class Siebel < DataServer
  # Donations should sometimes be deleted if they were misclassifed and then
  # later correctly re-classified. However, we have had 2 recent occasions when
  # the Siebel API incorectly returned no donations (or a lot fewer than
  # expected) and it caused MPDX users to unexpectedly lose bunches of
  # donations. So as a safety measure for that only remove a few donations per
  # import as typically only a couple at most will be misclassified.
  MAX_DONATIONS_TO_DELETE_AT_ONCE = 3

  def self.requires_username_and_password?
    false
  end

  def import_profiles
    designation_profiles = []

    profiles.each do |profile|
      designation_profile = Retryable.retryable do
        if profile.id
          @org.designation_profiles.where(user_id: @org_account.person_id, code: profile.id)
              .first_or_create(name: profile.name)
        else
          @org.designation_profiles.where(user_id: @org_account.person_id, code: nil)
              .first_or_create(name: profile.name)
        end
      end

      import_profile_balance(designation_profile)

      designation_profiles << designation_profile

      # Add included designation accounts
      profile.designations.each do |designation|
        find_or_create_designation_account(designation.number, designation_profile,  name: designation.description,
                                                                                     staff_account_id: designation.staff_account_id,
                                                                                     chartfield: designation.chartfield)
      end

      next if designation_profile.account_list

      AccountList::FromProfileLinker.new(designation_profile, @org_account)
                                    .link_account_list!
    end

    designation_profiles
  end

  def import_profile_balance(profile)
    total = 0
    # the profile balance is the sum of the balances from each designation account in that profile
    profile.designation_accounts.each do |da|
      next unless da.staff_account_id.present?
      balance = SiebelDonations::Balance.find(employee_ids: da.staff_account_id).first

      balance_amount = da.active? ? balance.primary : 0
      da.update(balance: balance_amount, balance_updated_at: Time.now)
      total += balance_amount
    end
    profile.update(balance: total, balance_updated_at: Time.now)
    profile
  end

  def import_donors(profile, date_from = nil)
    designation_numbers = profile.designation_accounts.pluck(:designation_number)

    return unless designation_numbers.present?
    account_list = profile.account_list

    SiebelDonations::Donor.find(having_given_to_designations: designation_numbers.join(','),
                                contact_filter: :all,
                                account_address_filter: :primary,
                                contact_email_filter: :all,
                                contact_phone_filter: :all).each do |siebel_donor|
      donor_account = add_or_update_donor_account(account_list, siebel_donor, profile, date_from)

      next unless siebel_donor.type == 'Business'
      add_or_update_company(account_list, siebel_donor, donor_account)
    end
  end

  def import_donations(profile, start_date = nil, end_date = nil)
    # if no date_from was passed in, use min date from query_ini
    rails_start_date = start_date
    if start_date.blank?
      start_date = @org.minimum_gift_date ? @org.minimum_gift_date : '01/01/2004'
      rails_start_date = Date.strptime(start_date, '%m/%d/%Y')
      start_date = rails_start_date.strftime('%Y-%m-%d')
    else
      start_date = start_date.strftime('%Y-%m-%d')
    end

    rails_end_date = end_date ? Date.strptime(end_date, '%m/%d/%Y') : Time.now
    end_date = rails_end_date.strftime('%Y-%m-%d')

    profile.designation_accounts.each do |da|
      donations = SiebelDonations::Donation.find(designations: da.designation_number,
                                                 posted_date_start: start_date,
                                                 posted_date_end: end_date)
      donations.each do |donation|
        add_or_update_donation(donation, da, profile)
      end

      # Sometimes the Siebel API flakes out and doesn't return any donations.
      # When that happened before it would cause all MPDX's donation records to
      # be destroyed (for Cru USA users). As a sanity check for that flaky API
      # condition, don't remove any donations if there are no donations in the
      # range we are checking (past 50 days typically).
      next if donations.empty?
      remove_deleted_siebel_donations(da, rails_start_date, rails_end_date,
                                      start_date, end_date)
    end
  end

  def remove_deleted_siebel_donations(da, rails_start_date, rails_end_date,
                                      start_date, end_date)
    # Check for removed donations
    all_current_donations_relation = da.donations.where('donation_date >= ? AND donation_date <= ?', rails_start_date, rails_end_date)
                                       .where.not(remote_id: nil)
    all_current_donations_array = all_current_donations_relation.to_a
    SiebelDonations::Donation.find(designations: da.designation_number, donation_date_start: start_date,
                                   donation_date_end: end_date).each do |siebel_donation|
      donation = all_current_donations_relation.find_by(remote_id: siebel_donation.id)
      all_current_donations_array.delete(donation)
    end

    donations_destroyed = 0
    # Double check removed donations straight from Siebel
    all_current_donations_array.each do |donation|
      next if donation.appeal.present?
      donation_date = donation.donation_date.strftime('%Y-%m-%d')
      siebel_donations = SiebelDonations::Donation.find(designations: da.designation_number, donors: donation.donor_account.account_number,
                                                        start_date: donation_date, end_date: donation_date)
      # The previous query might return a donation for the same date, so check that the remote_id is equal
      next unless siebel_donations.blank? ||
                  (siebel_donations.size == 1 && siebel_donations.first.id != donation.remote_id)
      donation.destroy

      donations_destroyed += 1
      break if donations_destroyed == MAX_DONATIONS_TO_DELETE_AT_ONCE
    end
  end

  def profiles_with_designation_numbers
    unless @profiles_with_designation_numbers
      @profiles_with_designation_numbers = profiles.map do |profile|
        { designation_numbers: profile.designations.map(&:number),
          name: profile.name,
          code: profile.id }
      end
    end
    @profiles_with_designation_numbers
  end

  def profiles
    unless @profiles
      if @org_account.user.relay_accounts.none?
        # This org account is no longer useful
        @org_account.destroy
        return []
      end
      Retryable.retryable(on: RestClient::InternalServerError, times: 3) do
        @profiles = SiebelDonations::Profile.find(ssoGuid: @org_account.remote_id)
      end
    end
    @profiles
  end

  protected

  def find_or_create_designation_account(number, profile, extra_attributes = {})
    @designation_accounts ||= {}
    unless @designation_accounts.key?(number)
      da = Retryable.retryable do
        @org.designation_accounts.where(designation_number: number).first_or_create
      end

      Retryable.retryable do
        profile.designation_accounts << da unless profile.designation_accounts.include?(da)
        da.update_attributes(extra_attributes) if extra_attributes.present?
        @designation_accounts[number] = da
      end
    end
    @designation_accounts[number]
  end

  def add_or_update_donation(siebel_donation, designation_account, profile)
    default_currency = @org.default_currency_code || 'USD'
    donor_account = @org.donor_accounts.find_by(account_number: siebel_donation.donor_id)

    # find donor account from siebel if we don't already have this donor
    unless donor_account
      siebel_donor = SiebelDonations::Donor.find(ids: siebel_donation.donor_id).first
      if siebel_donor
        account_list = profile.account_list
        donor_account = add_or_update_donor_account(account_list, siebel_donor, profile)
      end
    end

    unless donor_account
      Rollbar.raise_or_notify(Exception.new("Can't find donor account for #{siebel_donation.inspect}"))
      return
    end

    Retryable.retryable do
      date = Date.strptime(siebel_donation.donation_date, '%Y-%m-%d')

      attributes = {
        amount: siebel_donation.amount,
        channel: siebel_donation.channel,
        currency: default_currency,
        designation_account_id: designation_account.id,
        donation_date: date,
        donor_account_id: donor_account.id,
        motivation: siebel_donation.campaign_code,
        payment_method: siebel_donation.payment_method,
        payment_type: siebel_donation.payment_type,
        remote_id: siebel_donation.id,
        tendered_amount: siebel_donation.amount,
        tendered_currency: default_currency
      }

      donation = DonationImports::Base::FindDonation.new(designation_profile: profile, attributes: attributes).find_and_merge
      donation ||= Donation.new
      donation.update!(attributes)
      donation
    end
  end

  def add_or_update_company(account_list, siebel_donor, donor_account)
    master_company = MasterCompany.find_by(name: siebel_donor.account_name)

    company = @org_account.user.partner_companies.find_by(master_company_id: master_company.id) if master_company
    company ||= account_list.companies.new(master_company: master_company)

    contact = siebel_donor.primary_contact || SiebelDonations::Contact.new
    address = siebel_donor.primary_address || SiebelDonations::Address.new
    street = [address.address1, address.address2, address.address3, address.address4].compact.join("\n")

    company.attributes = {
      name: siebel_donor.account_name,
      phone_number: contact.primary_phone_number.try(:phone),
      street: street,
      city: address.city,
      state: address.state,
      postal_code: address.zip
    }
    company.save!

    donor_account.update_attribute(:master_company_id, company.master_company_id) unless donor_account.master_company_id == company.master_company.id
    company
  end

  def add_or_update_donor_account(account_list, donor, _profile, date_from = nil)
    Retryable.retryable do
      donor_account = @org.donor_accounts.where(account_number: donor.id).first_or_initialize
      donor_account.attributes = { name: donor.account_name,
                                   donor_type: donor.type }
      donor_account.save!

      contact = donor_account.link_to_contact_for(account_list)
      raise 'Failed to link to contact' unless contact

      # Save addresses
      donor.addresses&.each do |address|
        next if date_from.present? && DateTime.parse(address.updated_at) < date_from && contact.addresses.present?

        add_or_update_address(address, donor_account, donor_account)

        # Make sure the contact has the primary address
        add_or_update_address(address, contact, donor_account) if address.primary == true
      end

      # Save people (siebel calls them contacts)
      donor.contacts&.each do |person|
        next if date_from.present? && DateTime.parse(person.updated_at) < date_from && contact.people.present?

        add_or_update_person(person, donor_account, contact, date_from)
      end

      donor_account
    end
  end

  def add_or_update_person(siebel_person, donor_account, contact, date_from = nil)
    master_person_from_source = @org.master_people.find_by('master_person_sources.remote_id' => siebel_person.id)

    # If we didn't find someone using the real remote_id, try the "old style"
    unless master_person_from_source
      remote_id = siebel_person.primary ? "#{donor_account.account_number}-1" : "#{donor_account.account_number}-2"
      master_person_from_source = @org.master_people.find_by('master_person_sources.remote_id' => remote_id)
      if master_person_from_source
        MasterPersonSource.where(organization_id: @org.id, remote_id: remote_id).update_all(remote_id: siebel_person.id)
      end
    end

    person = contact.people.find_by(first_name: siebel_person.first_name, last_name: siebel_person.last_name)
    person ||= contact.people.find_by(master_person_id: master_person_from_source.id) if master_person_from_source
    person ||= Person.new(master_person: master_person_from_source)

    gender = case siebel_person.sex
             when 'F' then 'female'
             when 'M' then 'male'
             end

    person.attributes = {
      legal_first_name: siebel_person.first_name,
      first_name: siebel_person.preferred_name || siebel_person.first_name,
      last_name: siebel_person.last_name,
      middle_name: siebel_person.middle_name,
      title: siebel_person.title,
      suffix: siebel_person.suffix,
      gender: gender
    } if person.new_record?

    person.master_person_id ||= MasterPerson.find_or_create_for_person(person, donor_account: donor_account).try(:id)
    person.save!

    Retryable.retryable do
      donor_account.people << person unless donor_account.people.include?(person)
      donor_account.master_people << person.master_person unless donor_account.master_people.include?(person.master_person)
    end

    contact_person = contact.add_person(person, donor_account)

    # create the master_person_source if needed
    unless master_person_from_source
      Retryable.retryable do
        @org.master_person_sources.where(remote_id: siebel_person.id).first_or_create(master_person_id: person.master_person.id)
      end
    end

    # Phone Numbers
    siebel_person.phone_numbers&.each do |pn|
      next if date_from.present? && DateTime.parse(pn.updated_at) < date_from && contact_person.phone_numbers.present?

      add_or_update_phone_number(pn, person)

      # Make sure the contact person has the primary phone number
      add_or_update_phone_number(pn, contact_person) if pn.primary == true
    end

    # Email Addresses
    siebel_person.email_addresses&.each do |email|
      next if date_from.present? && DateTime.parse(email.updated_at) < date_from && contact_person.email_addresses.present?

      add_or_update_email_address(email, person)

      # Make sure the contact person has the primary phone number
      add_or_update_email_address(email, contact_person) if email.primary == true
    end

    [person, contact_person]
  end

  def add_or_update_address(address, object, source_donor_account)
    new_address = new_address_from_siebel(address, object, source_donor_account)

    place_match = object.addresses_including_deleted.find { |a| a.equal_to?(new_address) }
    remote_id_match = object.addresses_including_deleted.find { |a| a.remote_id == new_address.remote_id }
    address_to_update = place_match || remote_id_match

    # Remove the remote id from the old address if needed in case Siebel reuses address ids
    remote_id_match.update(remote_id: nil) if remote_id_match && place_match && place_match != remote_id_match

    if address_to_update
      address_to_update.assign_attributes(new_address.attributes.select { |_k, v| v.present? })
      address_to_update.save!(validate: false)
      new_or_updated_address = address_to_update
    else
      new_or_updated_address = object.addresses.create!(new_address.attributes)
    end

    if new_or_updated_address.primary_mailing_address?
      object.addresses.where.not(id: new_or_updated_address.id).update_all(primary_mailing_address: false)
    end
  rescue ActiveRecord::RecordInvalid => e
    raise e.message + " - #{address.inspect}"
  end

  def new_address_from_siebel(address, object, source_donor_account)
    current_primary = object.addresses.find_by(primary_mailing_address: true)
    make_primary = current_primary.blank? || (address.primary && current_primary.source == 'Siebel' &&
      source_donor_account.present? && current_primary.source_donor_account == source_donor_account)

    new_address = Address.new(street: [address.address1, address.address2, address.address3, address.address4].compact.join("\n"),
                              city: address.city,
                              state: address.state,
                              postal_code: address.zip,
                              primary_mailing_address: make_primary,
                              seasonal: address.seasonal,
                              location: address.type,
                              remote_id: address.id,
                              source: 'Siebel',
                              start_date: parse_date(address.updated_at),
                              source_donor_account: source_donor_account)

    # Set the master address so we can match by the same address formatted differently
    new_address.find_or_create_master_address

    new_address
  end

  def add_or_update_phone_number(phone_number, person)
    attributes = {
      number: phone_number.phone,
      location: phone_number.type.downcase,
      primary: phone_number.primary,
      remote_id: phone_number.id
    }
    existing_phone = person.phone_numbers.find { |pn| pn.remote_id == phone_number.id }
    if existing_phone
      existing_phone.update_attributes(attributes)
    else
      PhoneNumber.add_for_person(person, attributes)
    end
  end

  def add_or_update_email_address(email, person)
    attributes = {
      email: email.email,
      primary: email.primary,
      location: email.type,
      remote_id: email.id
    }
    Retryable.retryable do
      existing_email = person.email_addresses.find { |e| e.remote_id == email.id }
      if existing_email
        begin
          existing_email.update_attributes(attributes)
        rescue ActiveRecord::RecordNotUnique
          # If they already have the email address we're trying to update
          # to, don't do anything
        end
      else
        EmailAddress.add_for_person(person, attributes)
      end
    end
  end

  def check_credentials!() end
end

class SiebelError < StandardError
end
