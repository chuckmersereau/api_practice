class MailChimpHookHandler
  def initialize(mail_chimp_account)
    @mc_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def unsubscribe_hook(email)
    # No need to trigger a callback because MailChimp has already unsubscribed this email
    @account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })
      .update_all(optout_enewsletter: true)
  end

  def email_update_hook(old_email, new_email)
    ids_of_people_to_update = @account_list.people.joins(:email_addresses)
                              .where(email_addresses: { email: old_email, primary: true }).pluck(:id)

    Person.where(id: ids_of_people_to_update).includes(:email_addresses).each do |person|
      update_person_email(person, old_email, new_email)
    end
  end

  def email_cleaned_hook(email, reason)
    return unsubscribe_hook(email) if reason == 'abuse'

    emails = EmailAddress.joins(person: [:contacts])
             .where(contacts: { account_list_id: @account_list.id }, email: email)

    emails.each do |email_to_clean|
      email_to_clean.update(historic: true, primary: false)
      SubscriberCleanedMailer.delay.subscriber_cleaned(@account_list, email_to_clean)
    end
  end

  def campaign_status_hook(campaign_id, status, subject)
    return unless status == 'sent' && @mc_account.auto_log_campaigns
    @mc_account.queue_log_sent_campaign(campaign_id, subject)
  end

  private

  def update_person_email(person, old_email, new_email)
    old_email_record = person.email_addresses.find { |e| e.email == old_email }
    new_email_record = person.email_addresses.find { |e| e.email == new_email }

    if new_email_record
      new_email_record.primary = true
      old_email_record.primary = false
    else
      old_email_record.primary = false
      person.email_addresses << EmailAddress.new(email: new_email, primary: true)
    end
    person.save!
  end
end
