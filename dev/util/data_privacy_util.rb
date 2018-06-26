def anonymize_contacts_by_email(emails)
  if emails.blank?
    p 'No email addresses provided'
  end
  contacts = Contact.joins(people: :email_addresses).where(email_addresses: { email: emails })
  contacts.find_each do |contact|
    p "CONTACT: #{contact.id} #{contact.name}"
  end
  p "#{contacts.count} contact(s) found. Continue (Y/N)?"
  confirm = $stdin.gets.chomp.upcase
  return unless confirm == 'Y'
  contacts.find_each do |contact|
    ActiveRecord::Base.transaction do
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
    Rollbar.scope(contact: { id: contact.id }).info("PII Removal Completed for #{contact.id}")
    p "COMPLETED PII Removal for #{contact.id}"
  end
end
