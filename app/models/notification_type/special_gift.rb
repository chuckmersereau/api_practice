class NotificationType::SpecialGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.non_financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.designated_donations.where('donation_date > ?', 2.weeks.ago).last
  end

  def task_description_template
    '%{contact_name} gave a Special Gift of %{amount} on %{date}. Send them a Thank You.'
  end
end
