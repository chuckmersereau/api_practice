def build_test_data
  users.find_each{ |user|
    org_account = build_org_account(user, off_org)
    account_list = build_account_list(org_account)
    contact = build_contact(account_list)
    build_designation_profile(org_account, account_list)
    donor_account = build_donor_account(off_org, account_list, contact)
    build_donation(donor_account)
  }
end

def off_org
  @off_org ||= Organization.where(api_class: 'OfflineOrg').first
end

def users
  User.offset(30).limit(10)
end

def build_org_account(user, organization)
  Person::OrganizationAccount.create!(person_id: user.id,
                                      organization_id: organization.id)
end

def build_account_list(org_account)
  org_account.user.account_lists.create!(
      creator_id: org_account.user.id,
      name: org_account.user.to_s)
end

def build_contact(account_list)
  Contact.create!(name: "Test",
                  account_list_id: account_list.id)
end

def build_designation_profile(org_account, account_list)
  DesignationProfile.create!(
      user_id: org_account.person_id,
      organization_id: org_account.organization_id,
      account_list_id: account_list.id,
      code: org_account.id,
      name: org_account.user.to_s)
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
                   donation_date: Time.now,
                   amount: 15)
end
