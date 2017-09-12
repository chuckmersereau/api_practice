class Admin::AccountListResetWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_admin_account_list_reset_worker, retry: 3

  def perform(account_list_id, user_id, reset_log_id)
    @account_list = AccountList.find_by_id(account_list_id)
    @user = User.find(user_id)
    @reset_log = Admin::ResetLog.where(id: reset_log_id, resetted_user: @user).last!
    reset
    email_user
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
    set_default_account_list
    queue_import_organization_data
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

  def set_default_account_list
    @user.reload
    return if @user.default_account_list.present? && (@user.valid? || @user.errors[:default_account_list].blank?)
    @user.update(default_account_list: @user.account_lists&.first&.id)
  end

  def queue_import_organization_data
    @user.organization_accounts.each(&:queue_import_data)
  end

  def email_user
    AccountListResetMailer.delay.logout(@user, @reset_log)
  end
end
