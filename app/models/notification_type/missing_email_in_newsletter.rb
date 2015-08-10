class NotificationType::MissingEmailInNewsletter < NotificationType::MissingContactInfo
  def missing_info_filter(contacts)
    contacts.where(send_newsletter: %w(Both Email)).scoping do
      Contact.where.not(id: contacts_with_email.pluck(:id))
    end
  end

  def contacts_with_email
    Contact.joins(:contact_people)
      .joins('INNER JOIN email_addresses '\
             'ON email_addresses.person_id = contact_people.person_id')
      .where(email_addresses: { historic: [nil, false] })
  end

  def task_description_template
    '%{contact_name} is on the email newsletter but lacks a valid email address.'
  end
end
