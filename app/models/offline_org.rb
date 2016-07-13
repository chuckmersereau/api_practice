# This class stubs out data server stuff for orgs that don't have anything for us to download
require_dependency 'data_server'
class OfflineOrg < DataServer
  def import_all(_date_from = nil)
    # Do nothing
  end

  def import_profiles
    account_list = build_account_list
    designation_profile = build_designation_profile(account_list)
    designation_account = build_designation_account
    build_designation_profile_account(designation_profile, designation_account)
  end

  def self.requires_username_and_password?
    false
  end

  private

  def build_account_list
    account_list = @org_account.user.account_lists.find_or_create_by(
        creator_id: @org_account.user.id)
    account_list.update_attributes(name: @org_account.user.to_s)
    return account_list
  end

  def build_designation_profile(account_list)
    designation_profile = DesignationProfile.find_or_create_by!(
        user_id: @org_account.person_id,
        organization_id: @org.id,
        code: @org_account.id,
        account_list_id: account_list.id)
    designation_profile.update_attributes(name: @org_account.user.to_s)
    return designation_profile
  end

  def build_designation_account
    designation_account = DesignationAccount.find_or_create_by!(
        designation_number: @org_account.id,
        organization_id: @org.id,
        active: true)
    designation_account.update_attributes(name: @org_account.user.to_s)
    return designation_account
  end

  def build_designation_profile_account(designation_profile, designation_account)
    DesignationProfileAccount.find_or_create_by!(
        designation_account_id: designation_account.id,
        designation_profile_id: designation_profile.id)
  end
end
