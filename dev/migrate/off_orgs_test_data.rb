# Creates test data for users that belongs to offline organizations

def build_test_data
  users.find_each do |user|
    # Creates the organization account, account list and designation profile, according
    # to OrganizationAccount class for offline organizations
    build_org_account(user, off_org)
    account_list = build_account_list(user)
    build_designation_profile(off_org, user, account_list)

    # Creates a contact, with his donor account and generates a donation
    contact = build_contact(account_list)
    donor_account = build_donor_account(off_org, account_list, contact)
    build_donation(donor_account)
  end
end

def users
  User.offset(30).limit(10)
end

def off_org
  @off_org ||= Organization.where(api_class: 'OfflineOrg').first
end

def build_org_account(user, organization)
  Person::OrganizationAccount.create!(person_id: user.id,
                                      organization_id: organization.id,
                                      test_scene: true)
end

def build_account_list(user)
  user.account_lists.create!(name: user.to_s, creator_id: user.id)
end

def build_designation_profile(organization, user, account_list)
  organization.designation_profiles.create!(name: user.to_s,
                                            user_id: user.id,
                                            account_list_id: account_list.id)
end

def build_contact(account_list)
  Contact.create!(name: 'Test',
                  account_list_id: account_list.id)
end

def build_donor_account(organization, account_list, contact)
  donor_account = DonorAccount.create!(organization_id: organization.id,
                                       account_number: account_list.id)
  ContactDonorAccount.create!(donor_account_id: donor_account.id,
                              contact_id: contact.id)
end

def build_donation(donor_account)
  Donation.create!(donor_account_id: donor_account.id,
                   designation_account_id: nil,
                   donation_date: Time.now.utc,
                   amount: 15)
end
