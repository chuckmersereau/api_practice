class Person::GmailAccount
  attr_reader :google_account

  def initialize(google_account)
    @google_account = google_account
  end

  def gmail
    return false unless token?

    Gmail.connect(:xoauth2, google_account.email, google_account.token) do |gmail_client|
      yield gmail_client
    end
  end

  def import_emails(account_list, blacklisted_emails = [])
    return false unless token?
    self.blacklisted_emails = (blacklisted_emails.presence || []).collect(&:strip)

    since = (google_account.last_email_sync || 1.day.ago).to_date

    self.email_collection = AccountList::EmailCollection.new(account_list)

    gmail do |g|
      begin
        sent_mailbox     = g.mailbox('[Gmail]/Sent Mail')
        received_mailbox = g.mailbox('[Gmail]/All Mail')

        (since..Date.today).each do |date|
          sent_uids = sent_mailbox.fetch_uids(on: date) || []

          sent_uids.each_slice(20) do |uid_group|
            g.conn.uid_fetch(uid_group, Gmail::Message::PREFETCH_ATTRS).each do |imap_data|
              next unless imap_data

              gmail_message = Gmail::Message.new(sent_mailbox, nil, imap_data)
              log_sent_email(message: gmail_message)
            end
          end

          received_uids = received_mailbox.fetch_uids(on: date) || []

          received_uids.each_slice(20) do |uid_group|
            g.conn.uid_fetch(uid_group, Gmail::Message::PREFETCH_ATTRS).each do |imap_data|
              next unless imap_data

              gmail_message = Gmail::Message.new(received_mailbox, nil, imap_data)
              log_received_email(message: gmail_message)
            end
          end

          google_account.update_attributes(last_email_sync: date)
        end
      rescue Net::IMAP::NoResponseError => e
        # swallow it if the user doesn't have those mailboxes
        raise unless e.message.include?('Unknown Mailbox')
      end
    end
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
  rescue => error # Rescue all errors so that the sync can continue (otherwise it would repeat and get stuck at the same spot logging the same email).
    Rollbar.error(error) # Report the error so that we still know about it.
  end

  private

  attr_accessor :email_collection, :blacklisted_emails

  def token?
    !google_account.token_expired? || google_account.refresh_token!
  end

  def fetch_account_email_data(email_address)
    return unless email_address

    # While `email_collection.index_data[email_address]` could return an array of multiple items,
    # based on the possiblity that multiple Contacts can each have a person with the same email address -
    # we're selecting the first item in the array to maintain feature parity with legacy only fetching
    # and logging emails for an email address once.
    #
    # For context: https://github.com/CruGlobal/mpdx_api/blob/6412f535455c4959e3801c43143758f1438272ce/app/services/person/gmail_account.rb#L35-L46
    email_collection.select_by_email(email_address)&.first
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

  def log_received_email(message:)
    account_list_id      = email_collection.account_list.id
    sender_email_address = sender_email_address_from_envelope(message.envelope)
    account_email_data   = fetch_account_email_data(sender_email_address)

    return unless account_email_data.present? && log_emails_for_email_address?(account_email_data[:email])

    log_email(message, account_list_id, account_email_data[:contact_id], account_email_data[:person_id], 'Received')
  end

  def log_sent_email(message:)
    account_list_id           = email_collection.account_list.id
    recipient_email_addresses = recipient_email_addresses_from_envelope(message.envelope)

    recipient_email_addresses.each do |recipient_email_address|
      account_email_data = fetch_account_email_data(recipient_email_address)
      next unless account_email_data.present? && log_emails_for_email_address?(account_email_data[:email])

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

  def log_emails_for_email_address?(email)
    return false unless email
    !blacklisted_emails.include?(email)
  end
end
