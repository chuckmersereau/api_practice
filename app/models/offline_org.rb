# This class stubs out data server stuff for orgs that don't have anything for us to download
require_dependency 'data_server'
class OfflineOrg < DataServer
  def import_all(_date_from = nil)
    # Do nothing
  end

  def import_profiles
    profile = create_designation_profile
    create_designation_account(profile)
    AccountList::FromProfileLinker.new(profile, @org_account).link_account_list!
  end

  def self.requires_username_and_password?
    false
  end

  private

  def create_designation_profile
    @org.designation_profiles.where(
        user_id: @org_account.person_id,
        name: @org_account.user.to_s,
        code: @org_account.id.to_s
    ).first_or_create
  end

  def create_designation_account(profile)
    da = @org.designation_accounts.where(
        designation_number: @org_account.id.to_s,
        active: true
    ).first_or_create
    da.update(name: @org_account.user.to_s)
    profile.designation_accounts << da unless profile.designation_accounts.include?(da)
  end
end
