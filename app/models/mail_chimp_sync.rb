class MailChimpSync
  def initialize(mail_chimp_account)
    @mc_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def sync_contacts
    sync_adds_and_updates
    sync_deletes
  end

  def sync_adds_and_updates
    contacts_to_export = []
    newsletter_contacts.each do |news_contact|
      contact_id, person_id, mc_member_id = news_contact

      contact = Contact.find(contact_id)
      mc_member = MailChimpMember.find_by(id: mc_member_id)
      person = Person.find(person_id)

      if mc_member
        # Mail chimp member does exist, check for its fields
        unless mc_member.status == contact.status && 
          mc_member.greeting == contact.greeting && 
          mc_member.first_name == person.first_name &&
          mc_member.last_name == person.last_name

          contacts_to_export << contact
        end
      else
        contacts_to_export << contact
      end
    end
    @mc_account.export_to_list(contacts_to_export)
  end

  def sync_deletes
    @mc_account.unsubscribe_list_batch(@mc_account.primary_list_id, emails_to_remove)
  end

  def emails_to_remove
    (mc_members.pluck(:email).to_set - 
     newsletter_contacts.pluck('email_addresses.email').to_set).to_a
  end

  def newsletter_contacts
    @account_list.contacts.joins(:people)
      .joins('INNER JOIN email_addresses ON email_addresses.person_id = people.id')
      .where(send_newsletter: ['Email', 'Both'])
      .where(email_addresses: { primary: true })
      .where.not(email_addresses: { historic: false })
      .distinct
  end

  def mc_members
    @mc_account.mail_chimp_members.where(list_id: @mc_account.primary_list_id)
  end

  # Some ideas: 
  # 1. Use ruby code to check all contacts every time with the greeting
  # 2. Look at the last modified field similar to the Google contact sync
  # 3. Pass in a contact id and only check that.
  # 4. Combine approaches


  private

  def contacts_to_add_or_check_if_changed

  end

  def subscribes_needed_sql
    "
    SELECT uniq_newsletter_emails.email, uniq_newsletter_emails.person_id, contacts.id
    FROM #{uniq_newsletter_emails}
    INNER JOIN contact_people ON contact_people.person_id = uniq_newsletter_emails.person_id
    INNER JOIN contacts ON contacts.id = contact_people.contact_id
    LEFT JOIN mail_chimp_members mc_members
      ON mc_members.mail_chimp_account_id = :mail_chimp_account_id
      AND mc_members.list_id = :list_id
      AND mc_members.email = uniq_newsletter_emails.email
    "
  end

  def uniq_newsletter_emails_sql
    "(
    SELECT newsletter_emails.email, MIN(newsletter_emails.person_id) person_id
    FROM #{newsletter_emails_sql}
    GROUP BY newsletter_emails.email
    ) uniq_newsletter_emails"
  end

  def newsletter_emails_sql
    "(
    SELECT email_addresses.email, people.id person_id
    FROM contacts
    INNER JOIN contact_people ON contact_people.contact_id = contacts.id
    INNER JOIN people ON people.id = contact_people.person_id
    INNER JOIN email_addresses ON email_addresses.person_id = people.id
    WHERE contacts.account_list_id = :account_list_id
    AND contacts.send_newsletter IN ('Both', 'Email')
    AND email_addresses.primary = 't'
    AND (email_addresses.historic = 'f' OR email_addresses.historic is null)
    ) newsletter_emails"
  end


  def gb
    @mc_account.gb
  end
end
