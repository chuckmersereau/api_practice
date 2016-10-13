class Admin::Reset
  include ActiveModel::Model
  attr_accessor :reason, :admin_resetting, :user_finder, :reset_logger,
                :resetted_user, :resetted_user_email

  validates :reason, :resetted_user, presence: true

  def reset!
    @resetted_user = user_finder.find_user_by_email(resetted_user_email) if resetted_user_email
    return false unless valid?
    AccountList::Reset.new(@resetted_user.account_lists.first, @resetted_user).reset_shallow_and_queue_deep
    reset_logger.create!(admin_resetting: admin_resetting, resetted_user: @resetted_user, reason: reason)
    true
  end
end
