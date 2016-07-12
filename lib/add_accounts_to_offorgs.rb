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
      'api_class=? AND NOT EXISTS (?)', 'OfflineOrg',
      DesignationAccount.where(organization_id: organizations[:id]))
  end

  def add_accounts_to_off_org(org, org_account)
    account_list = org_account.user.account_lists.create!(
      name: org_account.user.to_s,
      creator_id: org_account.user.id)

    designation_account = DesignationAccount.create!(
      organization_id: org.id,
      name: org_account.user.to_s,
      active: true)

    designation_profile = DesignationProfile.create!(
      user_id: org_account.person_id,
      organization_id: org.id,
      name: org_account.user.to_s,
      code: org_account.id,
      account_list_id: account_list.id)

    DesignationProfileAccount.create!(
      designation_account_id: designation_account.id,
      designation_profile_id: designation_profile.id)
  end
end
