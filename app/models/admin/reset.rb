class Admin::Reset
  include ActiveModel::Model

  attr_accessor :reason, :admin_resetting, :user_finder, :reset_logger, :resetted_user_email, :account_list_name

  validates :reason, :resetted_user, :account_list, :reset_log, :admin_resetting, presence: true
  validate :account_list_is_unique

  def self.reset!(*args)
    new(*args).reset!
  end

  def reset!
    return false unless valid?
    authorize_reset_log
    save_reset_log
    queue_reset_job
    true
  end

  def account_list
    @account_list ||= account_list_scope&.first
  end

  private

  attr_accessor :reset_log

  def reset_log
    @reset_log ||= reset_logger.new(admin_resetting: admin_resetting, resetted_user: resetted_user, reason: reason)
  end

  def authorize_reset_log
    PunditAuthorizer.new(admin_resetting, reset_log).authorize_on('create')
  end

  def save_reset_log
    reset_log.save!
  end

  def queue_reset_job
    Admin::AccountListResetWorker.perform_async(account_list.id, resetted_user.id, reset_log.id)
  end

  def resetted_user
    @resetted_user ||= user_finder&.find_user_by_email(resetted_user_email)
  end

  def account_list_scope
    resetted_user&.account_lists&.where(name: account_list_name)
  end

  def account_list_is_unique
    return if account_list_scope&.count == 1
    errors[:account_list] << "is not unique or cannot be found, make sure the user's account list name is correct and also unique"
  end
end
