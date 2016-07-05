class NotificationType::LargerGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  def check_for_donation_to_notify(contact)
    larger_gift(contact) if had_larger_gift?(contact)
  end

  def had_larger_gift?(contact)
    return unless contact.pledge_frequency && contact.pledge_amount

    if contact.pledge_frequency < 1
      return contact.last_donation.present? && contact.last_donation.amount > contact.pledge_amount
    end

    return if long_time_frame_gift_given_early?(contact)

    contact.monthly_avg_current > contact.monthly_pledge &&
      contact.monthly_avg_with_prev_gift > contact.monthly_pledge &&
      !caught_up_earlier_months?(contact)
  end

  def caught_up_earlier_months?(contact)
    return unless contact.prev_month_donation_date
    from_date = contact.prev_month_donation_date << 1
    while from_date >= [Date.today << 12, contact.first_donation_date].compact.max
      return true if contact.monthly_avg_from(from_date) == contact.monthly_pledge
      from_date <<= contact.pledge_frequency
    end
  end

  def long_time_frame_gift_given_early?(contact)
    return unless contact.pledge_frequency.to_i >= LongTimeFrameGift::LONG_TIME_FRAME_PLEDGE_FREQUENCY &&
                  contact.prev_month_donation_date.present?
    contact.prev_donation_amount == contact.last_donation.amount && contact.last_donation.amount == contact.pledge_amount
  end

  def larger_gift(contact)
    contact.current_pledge_interval_donations.where.not(amount: contact.pledge_amount).first ||
      contact.last_donation
  end

  def task_description_template
    '%{contact_name} gave a larger than usual gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
