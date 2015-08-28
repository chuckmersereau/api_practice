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
    case
    when e.message.include?('code 250')
      # MMERGE3 must be provided - Please enter a value (code 250)
      # Notify user and nulify primary_list_id until they fix the problem
      @mc_account.update_column(:primary_list_id, nil)
      AccountMailer.mailchimp_required_merge_field(@account_list).deliver
    when e.message.include?('code 200')
      # Invalid MailChimp List ID (code 200)
      @mc_account.update_column(:primary_list_id, nil)
    when e.message.include?('code 502') || e.message.include?('code 220')
      # Invalid Email Address: "Rajah Tony" <amrajah@gmail.com> (code 502)
      # "jake.adams.photo@gmail.cm" has been banned (code 220) - Usually a typo in an email address
    when e.message.include?('code 214')
      # The new email address "xxxxx@example.com" is already subscribed to this list
    else
      raise e
    end
  end

  def sync_adds_and_updates(contact_ids)
    contacts_to_export = newsletter_contacts_with_emails(contact_ids)
                         .select(&method(:contact_changed_or_new?))
    return if contacts_to_export.empty?
    @mc_account.export_to_list(@mc_account.primary_list_id, contacts_to_export)
  end

  def sync_deletes
    newsletter_emails = newsletter_contacts_with_emails(nil).pluck('email_addresses.email')
    emails_to_remove = (members.pluck(:email).to_set - newsletter_emails.to_set).to_a
    return if emails_to_remove.empty?
    @mc_account.unsubscribe_list_batch(@mc_account.primary_list_id, emails_to_remove)
  end

  def newsletter_contacts_with_emails(contact_ids)
    @mc_account.contacts_with_email_addresses(contact_ids)
      .where(send_newsletter: %w(Email Both))
      .where.not(people: { optout_enewsletter: true })
  end

  private

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
