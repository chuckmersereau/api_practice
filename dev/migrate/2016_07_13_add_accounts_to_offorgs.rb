class AddAccountsToOfforgs
  def add_accounts_to_off_orgs
    off_orgs_with_no_designation_accounts.each do |org|
      org.organization_accounts.each do |org_account|
        org.api(org_account).import_profiles
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
end
