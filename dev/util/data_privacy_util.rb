def anonymize_contacts_by_email(emails)
  return if emails.blank?
  Contact.joins(people: :email_addresses).where(email_addresses: { email: emails }).find_each do |contact|
    new_contact_name = "DataPrivacy, Deleted #{Date.today.strftime('%Y/%m/%d')}"
    contact.taggings.destroy_all
    contact.tasks.destroy_all
    contact.addresses.destroy_all
    contact.people.destroy_all
    contact.contact_referrals_to_me.destroy_all
    contact.contact_referrals_by_me.destroy_all
    contact.donor_accounts.update_all(
      name: new_contact_name
    )
    contact.update(
      name: new_contact_name,
      pledge_amount: nil,
      status: 'Never Ask',
      notes: '',
      full_name: new_contact_name,
      greeting: '',
      website: '',
      church_name: '',
      send_newsletter: nil,
      timezone: nil,
      envelope_greeting: '',
      pledge_currency_code: nil,
      pledge_currency: nil,
      pledge_frequency: 0,
      likely_to_give: nil,
      locale: nil
    )
  end
end
