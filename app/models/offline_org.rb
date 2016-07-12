# This class stubs out data server stuff for orgs that don't have anything for us to download
require_dependency 'data_server'
class OfflineOrg < DataServer
  def import_all(_date_from = nil)
    # Do nothing
  end

  def import_profiles
    account_list = @org_account.user.account_lists.find_or_create_by(
      creator_id: @org_account.user.id)
    account_list.update_attributes(name: @org_account.user.to_s)

    designation_account = DesignationAccount.create!(
      designation_number: @org_account.id,
      organization_id: @org.id,
      name: @org_account.user.to_s,
      active: true)

    designation_profile = DesignationProfile.create!(
      user_id: @org_account.person_id,
      organization_id: @org.id,
      name: @org_account.user.to_s,
      code: @org_account.id,
      account_list_id: account_list.id)

    DesignationProfileAccount.create!(
      designation_account_id: designation_account.id,
      designation_profile_id: designation_profile.id)
  end

  def self.requires_username_and_password?
    false
  end
end
