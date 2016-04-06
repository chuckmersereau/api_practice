class AccountList::Reset
  def initialize(account_list, user)
    @account_list = account_list
    @user = user
  end

  def reset_shallow_and_queue_deep
    # This will have the effect of regenerating the account for the user from
    # the donor system.
    @account_list.account_list_users.destroy_all
    @account_list.designation_accounts.destroy_all
    @account_list.designation_profiles.destroy_all
    @user.organization_accounts.each(&:import_profiles)

    AccountList::DeepResetWorker.perform_async(@account_list.id, @user.id)
  end
end
