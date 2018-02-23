class NotificationType::SmallerGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if smaller_gift?(contact)
  end

  def smaller_gift?(contact)
    return unless contact.pledge_frequency && contact.pledge_amount

    without_gift_aid = contact.donations.without_gift_aid

    if contact.pledge_frequency < 1 && without_gift_aid.any?
      return contact.last_donation.present? &&
             contact.amount_with_gift_aid(without_gift_aid.first.amount) < contact.pledge_amount
    end

    monthly_avg_with_prev_gift_without_gift_aid =
      contact.amount_with_gift_aid(contact.monthly_avg_with_prev_gift)
    last_monthly_total_without_gift_aid =
      contact.amount_with_gift_aid(contact.monthly_avg_current(except_payment_method: Donation::GIFT_AID))
    monthly_avg_with_prev_gift_without_gift_aid < contact.monthly_pledge &&
      contact.last_monthly_total.positive? && last_monthly_total_without_gift_aid != contact.monthly_pledge &&
      !NotificationType::RecontinuingGift.had_recontinuing_gift?(contact)
  end

  def task_activity_type
    'To Do'
  end

  def task_description_template
    '%{contact_name} gave a gift of %{amount} on %{date}, which is different from their pledge. Research the gift.'
  end
end
