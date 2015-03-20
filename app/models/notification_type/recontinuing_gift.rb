class NotificationType::RecontinuingGift < NotificationType
  MONTHS_LATE_WHEN_RECONTINUED = 2

  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if self.class.had_recontinuing_gift?(contact)
  end

  def self.had_recontinuing_gift?(contact)
    return unless contact.pledge_amount && contact.pledge_frequency
    contact.last_monthly_total >= contact.pledge_amount &&
      contact.months_from_prev_to_last_donation.present? &&
      contact.months_from_prev_to_last_donation >= (contact.pledge_frequency + MONTHS_LATE_WHEN_RECONTINUED)
  end

  def task_description_template
    '%{contact_name} recontinued their giving with a gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
