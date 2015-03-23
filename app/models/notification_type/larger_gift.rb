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
    contact.monthly_avg_with_prev_gift > contact.monthly_pledge &&
      contact.monthly_avg_current > contact.monthly_pledge
  end

  def task_description_template
    '%{contact_name} gave an Extra Gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
