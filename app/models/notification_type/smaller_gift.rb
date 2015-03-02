class NotificationType::SmallerGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.last_donation if smaller_gift?(contact)
  end

  def smaller_gift?(contact)
    if contact.pledge_frequency < 1
      return contact.last_donation.present? && contact.last_donation.amount < contact.pledge_amount
    end
    contact.recent_monthly_avg < contact.monthly_pledge &&
      contact.last_monthly_total > 0 && contact.last_monthly_total != contact.pledge_amount &&
      !NotificationType::RecontinuingGift.had_recontinuing_gift?(contact)
  end

  def task_activity_type
    'To Do'
  end

  def task_description_template
    '%{contact_name} gave a gift of %{amount} on %{date}, which is different from their pledge. Research the gift.'
  end
end
