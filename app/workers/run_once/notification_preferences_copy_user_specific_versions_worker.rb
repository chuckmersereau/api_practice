# Execute 3
class NotificationPreferencesCopyUserSpecificVersionsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_run_once, unique: :until_executed

  def perform
    AccountListUser.includes(:user)
                   .where.not(people: { id: nil })
                   .find_each(&method(:duplicate_notification_preferences))
  end

  protected

  def duplicate_notification_preferences(account_list_user)
    account_list_user.account_list.notification_preferences.where(user_id: nil).find_each do |notification_preference|
      notification_preference.dup.tap do |user_notification_preference|
        user_notification_preference.uuid = nil
        user_notification_preference.user_id = account_list_user.user_id
        user_notification_preference.save!
      end
    end
  end
end
