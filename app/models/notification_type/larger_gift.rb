class NotificationType::LargerGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if larger_gift?(contact)
  end

  def larger_gift?(contact)
    return unless contact.pledge_frequency && contact.pledge_amount

    if contact.pledge_frequency < 1
      return contact.last_donation.present? && contact.last_donation.amount > contact.pledge_amount
    end

    contact.monthly_avg_current > contact.monthly_pledge &&
      contact.monthly_avg_with_prev_gift > contact.monthly_pledge &&
      !current_catches_up_earlier_months?(contact)
  end

  def current_catches_up_earlier_months?(contact)
    return unless contact.prev_month_donation_date
    from_date = contact.prev_month_donation_date << 1
    while from_date >= [1.year.ago, contact.first_donation_date].max
      return true if contact.monthly_avg_from(from_date) == contact.monthly_pledge
      from_date <<= 1
    end
  end

  def task_description_template
    '%{contact_name} gave an Extra Gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
