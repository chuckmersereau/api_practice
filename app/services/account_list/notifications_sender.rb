class AccountList::NotificationsSender
  def initialize(account_list)
    @account_list = account_list
    @notifications_to_email = {}
  end

  def send_notifications
    notifications = NotificationType.check_all(account_list)

    NotificationType.types.each do |notification_type_string|
      notification_type = notification_type_string.constantize.first
      next unless notifications[notification_type_string].present?
      create_tasks(notifications[notification_type_string], notification_type)
      queue_emails(notifications[notification_type_string], notification_type)
    end

    create_emails
  end

  private

  def create_tasks(notifications_of_type, notification_type)
    task_notification_preference =
      notification_preferences
      .find_by(notification_type_id: notification_type.id, user_id: nil, task: true)

    return unless task_notification_preference

    notifications_of_type.each do |notification|
      notification_type.create_task(account_list, notification)
    end
  end

  def queue_emails(notifications_of_type, notification_type)
    email_notification_preferences =
      notification_preferences
      .where(notification_type_id: notification_type.id, email: true)
      .where.not(user_id: nil)

    return unless email_notification_preferences.present?
    email_notification_preferences.each do |email_notification_preference|
      @notifications_to_email[email_notification_preference.user_id] ||=
        { user: email_notification_preference.user, notifications_by_type: {} }
      @notifications_to_email[email_notification_preference.user_id][:notifications_by_type][notification_type] =
        notifications_of_type
    end
  end

  def create_emails
    @notifications_to_email.each do |_key, notifications_by_user|
      NotificationMailer.delay.notify(
        notifications_by_user[:user],
        notifications_by_user[:notifications_by_type]
      )
    end
  end

  attr_reader :account_list, :notifications_to_email
  delegate :notification_preferences, to: :account_list
end
