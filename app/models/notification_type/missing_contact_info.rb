class NotificationType::MissingContactInfo < NotificationType
  def missing_info_filter(_contacts)
    raise 'This method must be implemented in a subclass'
  end

  def check(account_list)
    missing_info_filter(account_list.contacts).map do |contact|
      prior_notification = Notification.active
                                       .where(contact_id: contact.id, notification_type_id: id)
                                       .where('event_date > ?', 1.year.ago)
                                       .exists?
      next if prior_notification
      contact.notifications.create!(notification_type_id: id, event_date: Date.today)
    end.compact
  end

  def task_activity_type
    'To Do'
  end
end
