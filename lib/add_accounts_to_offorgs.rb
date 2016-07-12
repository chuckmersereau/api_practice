class AddAccountsToOfforgs
  def add_accounts_to_off_orgs
    off_orgs_with_no_designation_accounts.each do |org|
      org.organization_accounts.each do |org_account|
        add_accounts_to_off_org(org, org_account)
      end
    end
  end

  private

  def off_orgs_with_no_designation_accounts
    organizations = Organization.arel_table
    Organization.where(
      'api_class=? AND EXISTS (?) AND NOT EXISTS (?)', 'OfflineOrg',
      DesignationProfile.where(organization_id: organizations[:id]),
      DesignationAccount.where(organization_id: organizations[:id]))
  end

  def add_accounts_to_off_org(org, org_account)
    designation_profile = DesignationProfile.find_by(organization_id: org.id,
                                                     user_id: org_account.person_id)
    if designation_profile
      designation_account = DesignationAccount.create!(
          designation_number: org_account.id,
          organization_id: org.id,
          name: org_account.user.to_s,
          active: true)
      DesignationProfileAccount.create!(
          designation_account_id: designation_account.id,
          designation_profile_id: designation_profile.id)
    end
  end
end
