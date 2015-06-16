class NotificationType::RecontinuingGift < NotificationType
  MONTHS_LATE_WHEN_RECONTINUED = 2

  def check_contacts_filter(contacts)
    contacts.financial_partners.where.not(pledge_frequency: nil)
      .where('pledge_frequency < ?', LongTimeFrameGift::LONG_TIME_FRAME_PLEDGE_FREQUENCY)
      .where(pledge_received: true)
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if self.class.had_recontinuing_gift?(contact)
  end

  def self.had_recontinuing_gift?(contact)
    return unless contact.pledge_amount && contact.pledge_frequency

    # A gift is only "recontiuing" if the prior gift was given when the contact
    # was a financial partner.
    return unless contact.prev_month_donation_date.present? &&
                  contact.version_at(contact.prev_month_donation_date).status == 'Partner - Financial'

    contact.last_monthly_total >= contact.pledge_amount &&
      contact.months_from_prev_to_last_donation.present? &&
      contact.months_from_prev_to_last_donation >= (contact.pledge_frequency + MONTHS_LATE_WHEN_RECONTINUED)
  end

  def task_description_template
    '%{contact_name} recontinued their giving with a gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
