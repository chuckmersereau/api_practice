class MailChimpSync
  # So there is code in a few places:
  # callbacks
  # mail chimp account
  # mail chimp sync
  # appeals front end stuff
  # maybe other places ...
  # inputs into the process:
  # - contact is changed
  # - appeal list is exported
  # - sync now clicked

  def initialize(mail_chimp_account)
    @mc_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def sync_contacts
    sync_adds_and_updates
    sync_deletes
  end

  def sync_adds_and_updates
    contacts_to_export = @mc_account.contacts_with_email_addresses(nil)
      .select(&method(:contact_changed_or_new))

    return if contacts_to_export.empty?
    @mc_account.export_to_list(@mc_account.primary_list_id, contacts_to_export)
  end
  
  def contact_changed_or_new(contact)
    contact.people.reject(&:optout_enewsletter).any? do |person|
      member = members_by_email[person.primary_email_address.email]
      changed_or_new(contact, person, member)
    end
  end

  def members_by_email
    @members_by_email ||= Hash[mc_members.map { |m| [m.email, m] }]
  end

  def changed_or_new(contact, person, member)
    member.nil? || member.status != contact.status ||
      member.greeting != contact.greeting ||
      member.first_name != person.first_name ||
      member.last_name != person.last_name
  end

  def sync_deletes
    @mc_account.unsubscribe_list_batch(@mc_account.primary_list_id, emails_to_remove)
  end

  def emails_to_remove
    (mc_member_emails.to_set - newsletter_emails.to_set).to_a
  end

  def newsletter_emails
    @mc_account.contacts_with_email_addresses(nil).pluck('email_addresses.email')
  end

  def mc_member_emails
    mc_members.pluck(:email)
  end

  def mc_members
    @mc_account.mail_chimp_members.where(list_id: @mc_account.primary_list_id)
  end
end
