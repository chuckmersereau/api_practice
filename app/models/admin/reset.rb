class Admin::Reset
  include ActiveModel::Model
  attr_accessor :reason, :user_resetting_email, :user_finder, :reset_logger,
                :found_user

  validates :reason, :found_user, presence: true

  def reset!
    @found_user = user_finder.find_user_by_email(user_resetting_email)
    return false unless valid?
    AccountList::Reset.new(@found_user.account_list, @found_user).reset_shallow_and_queue_deep
    reset_logger.create!(admin_resetting: admin_user, resetted_user: @impersonated, reason: reason)
    true
  end
end
