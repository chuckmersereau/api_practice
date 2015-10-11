class MailChimpSync
  def initialize(mail_chimp_account)
    @mc_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def sync_contacts(contact_ids = nil)
    # Scope the search for edits and updates to the passed contact ids, but the
    # logic for the deletes requires checking the full list.
    sync_adds_and_updates(contact_ids)
    sync_deletes
  rescue Gibbon::MailChimpError => e
    @mc_account.handle_newsletter_mc_error(e)
  end

  def sync_adds_and_updates(contact_ids)
    contacts_to_export = select_contacts_to_export(contact_ids)
    return if contacts_to_export.empty?
    @mc_account.export_to_list(@mc_account.primary_list_id, contacts_to_export)
  end

  def sync_deletes
    emails_to_remove = members.pluck(:email) - @mc_account.newsletter_emails
    return if emails_to_remove.empty?
    @mc_account.unsubscribe_list_batch(@mc_account.primary_list_id, emails_to_remove)
  end

  private

  def select_contacts_to_export(contact_ids)
    to_export = []
    @mc_account.newsletter_contacts_with_emails(contact_ids).find_each do |contact|
      to_export << contact if contact_changed_or_new?(contact)
    end
    to_export
  end

  def contact_changed_or_new?(contact)
    contact.people.any? do |person|
      member = members_by_email[person.primary_email_address.email]
      contact_person_changed_or_new?(contact, person, member)
    end
  end

  def contact_person_changed_or_new?(contact, person, member)
    member.nil? || member.status != contact.status ||
      member.greeting != contact.greeting ||
      member.first_name != person.first_name ||
      member.last_name != person.last_name
  end

  def members_by_email
    @members_by_email ||= Hash[members.map { |m| [m.email, m] }]
  end

  def members
    @mc_account.mail_chimp_members.where(list_id: @mc_account.primary_list_id)
  end
end
