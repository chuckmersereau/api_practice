class NotificationType::TaskIfPeriodPast < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  # Check to see if this designation_account has no actitivities that should trigger a notification
  def check(account_list)
    notifications = []
    check_contacts_filter(account_list.contacts).each do |contact|
      next unless contact.created_at < 1.year.ago || contact.activities.where('start_at < ?', 1.year.ago).any?
      prior_notification = Notification.active.where(contact_id: contact.id, notification_type_id: id)
                           .find_by('event_date > ?', 1.year.ago)
      next if prior_notification
      next unless notify_for_contact?(contact)
      notification = contact.notifications.create!(notification_type_id: id, event_date: Date.today)
      notifications << notification
    end
    notifications
  end

  def notify_for_contact?(contact)
    contact.tasks.where('start_at > ?', past_period_to_check).where(activity_type: task_type_to_check).empty?
  end

  def past_period_to_check
    1.year.ago
  end

  def task_type_to_check
    task_activity_type
  end

  def task_description(notification)
    _(task_description_template).localize %
      { contact_name: notification.contact.name }
  end

  def task_description_template
    fail 'This method must be implemented in a subclass'
  end
end
