class Admin::AccountListResetWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_admin_account_list_reset_worker, retry: 3

  def perform(account_list_id, user_id, reset_log_id)
    @account_list = AccountList.find_by_id(account_list_id)
    @user = User.find(user_id)
    @reset_log = Admin::ResetLog.where(id: reset_log_id, resetted_user: @user).last!
    reset
  rescue ActiveRecord::RecordNotFound, Pundit::NotAuthorizedError => exception
    Rollbar.error(exception)
    false
  else
    true
  end

  private

  def reset
    authorize_reset_log
    destroy_account_list
    import_profiles
    async_import_donor_data
    @reset_log.update_column(:completed_at, Time.current)
  end

  def authorize_reset_log
    PunditAuthorizer.new(@reset_log.admin_resetting, @reset_log).authorize_on('create')
  end

  def destroy_account_list
    return if @account_list.blank?
    AccountList::Destroyer.new(@account_list.id).destroy!
  end

  def import_profiles
    @user.organization_accounts.each(&:import_profiles)
  end

  def async_import_donor_data
    @user.organization_accounts.each(&:queue_import_data)
  end
end
