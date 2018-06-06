class NotificationType::SpecialGift < NotificationType
  def check_contacts_filter(contacts)
    contacts.non_financial_partners
  end

  def check_for_donation_to_notify(contact)
    contact.donations.where('donation_date > ?', 1.month.ago).last
  end

  def task_description_template(notification = nil)
    if notification&.account_list&.designation_accounts&.many?
      _('%{contact_name} gave a Special Gift of %{amount} on %{date} to %{designation}. Send them a Thank You.')
    else
      _('%{contact_name} gave a Special Gift of %{amount} on %{date}. Send them a Thank You.')
    end
  end
end
