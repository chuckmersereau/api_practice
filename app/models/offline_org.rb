# This class stubs out data server stuff for orgs that don't have anything for us to download
require_dependency 'data_server'
class OfflineOrg < DataServer
  def import_all(_date_from = nil)
    # Do nothing
  end

  def import_profiles
    designation_profile = create_designation_profile(account_list)
    designation_account = create_designation_account
    create_designation_profile_account(designation_profile, designation_account)
  end

  def self.requires_username_and_password?
    false
  end

  private

  def account_list
    @org_account.user.account_lists.find_by(creator_id: @org_account.user.id)
  end

  def create_designation_profile(account_list)
    designation_profile = DesignationProfile.find_or_create_by!(
      user_id: @org_account.person_id,
      organization_id: @org.id,
      account_list_id: account_list.id
    ) do |dp|
      dp.code = @org_account.id.to_s
    end
    designation_profile.update(name: @org_account.user.to_s)
    designation_profile
  end

  def create_designation_account
    designation_account = DesignationAccount.find_or_create_by!(
      organization_id: @org.id,
      active: true,
      designation_number: @org_account.id.to_s)
    designation_account.update(name: @org_account.user.to_s)
    designation_account
  end

  def create_designation_profile_account(designation_profile, designation_account)
    DesignationProfileAccount.find_or_create_by!(
      designation_account_id: designation_account.id,
      designation_profile_id: designation_profile.id)
  end
end
