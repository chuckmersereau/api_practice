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
    off_orgs = []
    Organization.where(api_class: 'OfflineOrg').find_each do |org|
      result = DesignationProfileAccount.where(
        'designation_profile_id IN (?) AND designation_account_id NOT IN (?)',
        org.designation_profiles.collect(&:id),
        org.designation_accounts.collect(&:id))
      off_orgs << org if result.empty?
    end
    off_orgs
  end
end
