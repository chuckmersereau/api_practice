class NotificationType::StartedGiving < NotificationType
  def check(account_list)
    notifications = []
    account_list.contacts.where(account_list_id: account_list.id).financial_partners.each do |contact|
      prior_notification = Notification.active.find_by(contact_id: contact.id, notification_type_id: id)
      next if prior_notification

      # update pledge received in case there are past donations
      orig_pledge_received = contact.pledge_received?
      donation = last_donation_within_pledge_freq(contact)
      contact.pledge_received = true if donation.present? && contact.pledge_amount == donation.amount
      contact.save

      # If they just gave their first gift, note it as such
      next unless !orig_pledge_received && donation &&
                  contact.donations.where('donation_date < ?', 2.weeks.ago).count == 0

      # update pledge amount
      contact.pledge_amount = donation.amount if contact.pledge_amount.blank?
      contact.pledge_currency = donation.currency if contact.pledge_currency != donation.currency

      # recheck pledge_received in case pledge_amount was blank before
      contact.pledge_received = true if contact.pledge_amount == donation.amount
      contact.pledge_frequency ||= 1 # default to monthly pledge if nil
      contact.save

      notification = contact.notifications.create!(notification_type_id: id, event_date: Date.today)
      notifications << notification
    end
    notifications
  end

  def create_task(account_list, notification)
    contact = notification.contact
    task = account_list.tasks.create(subject: task_description(notification), start_at: Time.now,
                                     activity_type: _('Thank'), notification_id: notification.id)
    task.activity_contacts.create(contact_id: contact.id)
    task
  end

  def task_description(notification)
    _('%{contact_name} just gave their first gift. Send them a Thank You.').localize %
      { contact_name: notification.contact.name }
  end

  private

  def last_donation_within_pledge_freq(contact)
    # Default past period to 2 weeks so we can set the pledge info above when
    # the first gift comes for a partner with no pledge info set.
    past_pledge_period_start = pledge_freq_months_ago(contact) || 2.weeks.ago

    # Donation sort order is by donation_date descending by default
    contact.donations.find_by('donation_date > ?', past_pledge_period_start)
  end

  def pledge_freq_months_ago(contact)
    return unless contact.pledge_frequency.present?

    if contact.pledge_frequency < 1
      (contact.pledge_frequency * 30).days.ago
    else
      contact.pledge_frequency.to_i.months.ago
    end
  end
end
