class AccountList::NotificationsSender
  def initialize(account_list)
    @account_list = account_list
  end

  def send_notifications
    notifications = NotificationType.check_all(account_list)

    notifications_to_email = {}

    # Check preferences for what to do with each notification type
    NotificationType.types.each do |notification_type_string|
      notification_type = notification_type_string.constantize.first

      next unless notifications[notification_type_string].present?
      actions = notification_preferences.find_by_notification_type_id(notification_type.id).try(:actions) ||
                NotificationPreference.default_actions

      # Collect any emails that need sent
      if actions.include?('email')
        notifications_to_email[notification_type] = notifications[notification_type_string]
      end

      next unless actions.include?('task')
      # Create a task for each notification
      notifications[notification_type_string].each do |notification|
        notification_type.create_task(account_list, notification)
      end
    end

    # Send email if necessary
    if notifications_to_email.present?
      NotificationMailer.notify(account_list, notifications_to_email).deliver
    end
  end

  private

  attr_reader :account_list
  delegate :notification_preferences, to: :account_list
end
