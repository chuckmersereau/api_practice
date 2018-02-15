# Execute 2
class RunOnce::NotificationPreferencesConvertActionsArrayToBooleansWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_run_once, unique: :until_executed

  def perform(since = Time.at(0))
    NotificationPreference.where('updated_at > ?', since).find_each(&method(:convert_actions_array_to_booleans))
  end

  protected

  def convert_actions_array_to_booleans(notification_preference)
    notification_preference.update_attributes(
      email: notification_preference.actions.include?('email'),
      task: notification_preference.actions.include?('task')
    )
  end
end
