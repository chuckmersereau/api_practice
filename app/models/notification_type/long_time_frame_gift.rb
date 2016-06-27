class NotificationType::LongTimeFrameGift < NotificationType
  LONG_TIME_FRAME_PLEDGE_FREQUENCY = 6

  def check(account_list)
    notifications = []
    check_contacts_filter(account_list.contacts).each do |contact|
      donation = check_for_donation_to_notify(contact)
      next unless donation && donation.donation_date > 90.days.ago # Increase the number of days for checking
      next if Notification.active.where(notification_type_id: id, donation_id: donation.id).present?
      notification = contact.notifications.create!(notification_type_id: id, donation: donation, event_date: Date.today)
      notifications << notification
    end
    notifications
  end

  def check_contacts_filter(contacts)
    contacts.financial_partners.where('pledge_amount > 0')
            .where('pledge_frequency >= ?', LONG_TIME_FRAME_PLEDGE_FREQUENCY)
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if contact.prev_month_donation_date.present? &&
                             contact.last_long_time_frame_total == contact.pledge_amount
  end

  def task_description(notification)
    template = '%{contact_name} gave their %{frequency} gift of %{amount} on %{date}. Send them a Thank You.'
    _(template).localize %
      { contact_name: notification.contact.name, amount: notification.donation.localized_amount,
        date: notification.donation.localized_date,
        frequency: _(Contact.pledge_frequencies[notification.contact.pledge_frequency]) }
  end
end
