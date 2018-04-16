class NotificationType::LongTimeFrameGift < NotificationType
  LONG_TIME_FRAME_PLEDGE_FREQUENCY = 6

  def check_contacts_filter(contacts)
    contacts.financial_partners.where('pledge_amount > 0')
            .where('pledge_frequency >= ?', LONG_TIME_FRAME_PLEDGE_FREQUENCY)
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if contact.prev_month_donation_date.present? &&
                             contact.last_monthly_total == contact.pledge_amount
  end

  def interpolation_values(notification)
    super(notification).merge(frequency: _(Contact.pledge_frequencies[notification.contact.pledge_frequency]))
  end

  def task_description_template
    _('%{contact_name} gave their %{frequency} gift of %{amount} on %{date}. Send them a Thank You.')
  end
end
