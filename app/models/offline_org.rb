# This class stubs out data server stuff for orgs that don't have anything for us to download
require_dependency 'data_server'
class OfflineOrg < DataServer
  def import_all(_date_from = nil)
    # Do nothing
  end

  def import_test_profiles
    method(:import_profiles).super_method.call
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
    dps = @org.designation_profiles.where(user_id: @org_account.person_id)

    if dps.empty?
      dp = @org.designation_profiles.create!(
        user_id: @org_account.person_id,
        code: @org_account.id.to_s,
        name: @org_account.user.to_s
      )
    else
      dp = dps.find_by(code: @org_account.id.to_s)
      if dp.nil?
        dp = dps.first
        dp.update(code: @org_account.id.to_s, name: @org_account.user.to_s)
      else
        dp.update(name: @org_account.user.to_s)
      end
    end

    dp
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
