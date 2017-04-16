class Person::GmailAccount
  attr_reader :google_account

  def initialize(google_account)
    @google_account = google_account
  end

  def client
    @client ||= google_account.client
  end

  def gmail
    return false if google_account.token_expired? && !google_account.refresh_token!

    begin
      client = Gmail.connect(:xoauth2, google_account.email, google_account.token)
      yield client
    ensure
      begin
        client.logout
      rescue
      end
    end
  end

  def folders
    @folders ||= client.labels.all
  end

  def import_emails(account_list)
    return false unless client

    since = google_account.last_email_sync || 1.hour.ago
    email_collection = AccountListEmailCollection.new(account_list)

    gmail do |g|
      begin
        # sent emails
        sent = g.mailbox('[Gmail]/Sent Mail')
        sent.emails(after: since).each do |gmail_message|
          log_sent_email(message: gmail_message, email_collection: email_collection)
        end

        # received emails
        all = g.mailbox('[Gmail]/All Mail')
        all.emails(after: since).each do |gmail_message|
          log_received_email(message: gmail_message, email_collection: email_collection)
        end
      rescue Net::IMAP::NoResponseError => e
        # swallow it if the user doesn't have those mailboxes
        raise unless e.message.include?('Unknown Mailbox')
      end
    end

    google_account.update_attributes(last_email_sync: Time.now)
  end

  def log_email(gmail_message, account_list_id, contact_id, person_id, result)
    contact = Contact.find(contact_id)

    subject = format_subject(gmail_message.subject)
    body    = format_message_body(gmail_message.message)
    return unless body

    google_email = google_account.google_emails.find_or_create_by!(google_email_id: gmail_message.msg_id)
    return if contact.tasks.exists?(id: google_email.activities.ids)

    task = contact.tasks.create!(subject: subject,
                                 start_at: gmail_message.envelope.date,
                                 completed: true,
                                 completed_at: gmail_message.envelope.date,
                                 account_list_id: account_list_id,
                                 activity_type: 'Email',
                                 result: result,
                                 remote_id: gmail_message.envelope.message_id,
                                 source: 'gmail')

    task.comments.create!(body: body, person_id: person_id)
    google_email.activities << task
    google_email.save!

    task
  end

  private

  def fetch_account_email_data(email_collection, email_address)
    return unless email_address

    # While `email_collection.index_data[email_address]` could return an array of multiple items,
    # based on the possiblity that multiple Contacts can each have a person with the same email address -
    # we're selecting the first item in the array to maintain feature parity with legacy only fetching
    # and logging emails for an email address once.
    #
    # For context: https://github.com/CruGlobal/mpdx_api/blob/6412f535455c4959e3801c43143758f1438272ce/app/services/person/gmail_account.rb#L35-L46
    email_collection.indexed_data[email_address]&.first
  end

  def force_encode_body(body_needing_encoding)
    body_needing_encoding
      .body
      .decoded
      .to_s
      .unpack('C*')
      .pack('U*')
      .force_encoding('UTF-8')
      .encode!
      .delete("\0")
  end

  def format_message_body(message_body)
    body = message_body.multipart? ? message_body.text_part : message_body
    return unless body

    encoded_body = force_encode_body(body)
    return unless encoded_body.strip.present?

    encoded_body
  end

  def format_subject(gmail_message_subject)
    if gmail_message_subject.present?
      gmail_message_subject.truncate(2000, omission: '')
    else
      _('No Subject')
    end
  end

  def log_received_email(message:, email_collection:)
    account_list_id      = email_collection.account_list.id
    sender_email_address = sender_email_address_from_envelope(message.envelope)
    account_email_data   = fetch_account_email_data(email_collection, sender_email_address)

    return unless account_email_data.present?

    log_email(message, account_list_id, account_email_data[:contact_id], account_email_data[:person_id], 'Received')
  end

  def log_sent_email(message:, email_collection:)
    account_list_id           = email_collection.account_list.id
    recipient_email_addresses = recipient_email_addresses_from_envelope(message.envelope)

    recipient_email_addresses.each do |recipient_email_address|
      account_email_data = fetch_account_email_data(email_collection, recipient_email_address)
      next unless account_email_data.present?

      log_email(message, account_list_id, account_email_data[:contact_id], account_email_data[:person_id], 'Done')
    end
  end

  def recipient_email_addresses_from_envelope(envelope)
    envelope.to.to_a.map do |address|
      "#{address.mailbox}@#{address.host}"
    end
  end

  def sender_email_address_from_envelope(envelope)
    address = envelope.sender&.first

    return unless address

    "#{address.mailbox}@#{address.host}"
  end
end
