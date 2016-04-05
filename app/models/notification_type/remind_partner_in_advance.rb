class NotificationType::RemindPartnerInAdvance < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners.where(['pledge_start_date is NULL OR pledge_start_date < ?', 30.days.ago])
            .where(direct_deposit: false)
            .where('pledge_frequency >= ?', 3.0)
  end

  def check(account_list)
    notifications = []
    check_contacts_filter(account_list.contacts).each do |contact|
      next unless contact.pledge_received?
      next unless early_by?(1.month, contact)
      prior_notification = Notification.active.where(contact_id: contact.id, notification_type_id: id)
                                       .find_by('event_date > ?', 2.months.ago)
      next if prior_notification
      next unless contact.donations.any?
      notification = contact.notifications.create!(notification_type_id: id, event_date: Time.zone.today)
      notifications << notification
    end
    notifications
  end

  def early_by?(days, contact)
    date_to_check = contact.last_donation_date || contact.pledge_start_date
    return false unless date_to_check.present?
    next_gift_date = date_to_check + contact.pledge_frequency.to_i.months
    next_gift_date > Time.zone.today && next_gift_date <= Time.zone.today + days + 1.day
  end

  def create_task(account_list, notification)
    contact = notification.contact
    task = account_list.tasks.create(subject: task_description(notification), start_at: Time.zone.now,
                                     activity_type: _('To Do'), notification_id: notification.id)
    task.activity_contacts.create(contact_id: contact.id)
    task
  end

  def task_description(notification)
    _('%{contact_name} have an expected gift in one month. Contact to follow up.').localize %
      { contact_name: notification.contact.name }
  end
end
