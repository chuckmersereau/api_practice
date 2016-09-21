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
      return contact.last_donation.present? && contact.amount_with_gift_aid(contact.donations
                                                                                   .without_gift_aid
                                                                                   .first.amount) > contact.pledge_amount
    end
    
    return if long_time_frame_gift_given_early?(contact)

    monthly_avg_without_gift_aid = contact.amount_with_gift_aid(contact.monthly_avg_current(except_payment_method: Donation::GIFT_AID))
    monthly_avg_with_prev_gift_without_gift_aid = contact.amount_with_gift_aid(contact.monthly_avg_with_prev_gift)
    monthly_avg_without_gift_aid > contact.monthly_pledge &&
      monthly_avg_with_prev_gift_without_gift_aid > contact.monthly_pledge &&
      !caught_up_earlier_months?(contact)
  end

  def caught_up_earlier_months?(contact)
    return unless contact.prev_month_donation_date
    from_date = contact.prev_month_donation_date << 1
    while from_date >= [Date.today << 12, contact.first_donation_date].compact.max
      monthly_avg_without_gift_aid = contact.amount_with_gift_aid(contact.monthly_avg_from(from_date, except_payment_method: Donation::GIFT_AID))
      return true if monthly_avg_without_gift_aid == contact.monthly_pledge
      from_date <<= contact.pledge_frequency
    end
  end

  def long_time_frame_gift_given_early?(contact)
    return unless contact.pledge_frequency.to_i >= LongTimeFrameGift::LONG_TIME_FRAME_PLEDGE_FREQUENCY &&
                  contact.prev_month_donation_date.present?
    last_donation_month_end = contact.last_donation_date.end_of_month
    previous_frame_start_date = (last_donation_month_end << contact.pledge_frequency - 1).beginning_of_month
    previous_frame_end_date = (last_donation_month_end << 1).end_of_month
    prev_donation_amount = contact.donations.where('donation_date >= ? AND donation_date <= ?',
                                                   previous_frame_start_date,
                                                   previous_frame_end_date).sum(:amount)
    prev_donation_amount == contact.last_donation.amount &&
      prev_donation_amount == contact.pledge_amount
  end

  def larger_gift(contact)
    contact.current_pledge_interval_donations.where.not(amount: contact.pledge_amount).first ||
      contact.last_donation
  end

  def task_description_template
    '%{contact_name} gave a larger than usual gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
