class NotificationType < ApplicationRecord
  # attr_accessible :description, :type

  def initialize(*args)
    @contacts ||= {}
    super
  end

  def self.types
    @@types ||= connection.select_values("select distinct(type) from #{table_name}")
  end

  def self.check_all(account_list)
    contacts = {}
    types.each do |type|
      type_instance = type.constantize.first
      next unless account_list
                  .notification_preferences
                  .where(notification_type_id: type_instance.id)
                  .where('"notification_preferences"."email" = true OR "notification_preferences"."task" = true')
                  .exists?
      contacts[type] = type_instance.check(account_list)
    end.compact
    contacts
  end

  # Check to see if this designation_account has donations that should trigger a notification
  def check(account_list)
    notifications = []
    check_contacts_filter(account_list.contacts).each do |contact|
      donation = check_for_donation_to_notify(contact)
      next unless donation && donation.donation_date > 60.days.ago # Don't notify for old gifts
      next if Notification.active.where(notification_type_id: id, donation_id: donation.id).present?
      notification = contact.notifications.create!(notification_type_id: id, donation: donation, event_date: Date.today)
      notifications << notification
    end
    notifications
  end

  # Create a task that corresponds to this notification
  def create_task(account_list, notification)
    contact = notification.contact
    task = account_list.tasks.create(subject: task_description(notification), start_at: Time.now,
                                     no_date: $rollout.active?(:no_date_task, account_list),
                                     activity_type: _(task_activity_type), notification_id: notification.id)
    task.activity_contacts.create(contact_id: contact.id)
    task
  end

  def task_description(notification)
    _(task_description_template).localize %
      { contact_name: notification.contact.name, amount: notification.donation.localized_amount,
        date: notification.donation.localized_date }
  end

  protected

  def task_description_template
    raise 'This method (or create_task and task_description) must be implemented in a subclass'
  end

  def task_activity_type
    'Thank'
  end

  def check_contacts_filter(contacts)
    contacts
  end

  def check_for_donation_to_notify(_contact)
    raise 'This method (or check) must be implemented in a subclass'
  end
end
