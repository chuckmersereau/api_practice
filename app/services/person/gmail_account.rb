# This class has the potential to be broken out into several classes to handle
# gmail account importing. It could then be packaged up into a library/gem.
class Person::GmailAccount
  attr_reader :google_account, :since

  def initialize(google_account)
    @google_account = google_account
    @since = (google_account.last_email_sync || 1.day.ago).to_date
  end

  def gmail_connection
    return false unless token?

    Gmail.connect(:xoauth2, google_account.email, google_account.token) do |gmail_client|
      yield gmail_client
    end
  end

  def import_emails(account_list, blacklisted_emails = [])
    return false unless token?
    self.blacklisted_emails = (blacklisted_emails.presence || []).collect(&:strip)
    self.email_collection = AccountList::EmailCollection.new(account_list)

    gmail_connection do |gmail|
      begin
        sent_mailbox     = gmail.mailbox('[Gmail]/Sent Mail')
        received_mailbox = gmail.mailbox('[Gmail]/All Mail')

        (since..Date.today).each do |date|
          process_sent_emails(gmail, sent_mailbox, date)
          process_received_emails(gmail, received_mailbox, date)
          google_account.update_attributes(last_email_sync: date)
        end
      rescue Net::IMAP::NoResponseError => e
        # swallow it if the user doesn't have those mailboxes
        raise unless e.message.include?('Unknown Mailbox')
      end
    end
  end

  def record_email(gmail_message, account_list_id, contact_id, person_id, result)
    contact = Contact.find(contact_id)
    body    = format_message_body(gmail_message.message)
    return unless body

    google_email = google_account.google_emails.find_or_create_by!(google_email_id: gmail_message.msg_id)
    return if contact.tasks.exists?(id: google_email.activities.ids)
    task = create_task_for_contact(gmail_message, account_list_id, contact, result)

    task.comments.create!(body: body, person_id: person_id)
    google_email.activities << task
    google_email.save!

    task
  # Rescue all errors so that the sync can continue (otherwise it would
  # repeat and get stuck at the same spot logging the same email).
  rescue StandardError => error
    Rollbar.error(error) # Report the error so that we still know about it.
  end

  private

  attr_accessor :email_collection, :blacklisted_emails

  def token?
    !google_account.token_expired?
  end

  def fetch_account_email_data(email_address)
    return unless email_address

    # While `email_collection.index_data[email_address]` could return an array of multiple items,
    # based on the possiblity that multiple Contacts can each have a person with the same email address -
    # we're selecting the first item in the array to maintain feature parity with legacy only fetching
    # and logging emails for an email address once.
    #
    # For context: https://github.com/CruGlobal/mpdx_api/blob/6412f53/app/services/person/gmail_account.rb#L35-L46
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

  def record_received_email(message:)
    account_list_id      = email_collection.account_list.id
    sender_email_address = sender_email_address_from_envelope(message.envelope)
    account_email_data   = fetch_account_email_data(sender_email_address)

    return unless account_email_data.present? && not_blacklisted?(account_email_data[:email])

    record_email(message, account_list_id, account_email_data[:contact_id], account_email_data[:person_id], 'Received')
  end

  def record_sent_email(message:)
    account_list_id           = email_collection.account_list.id
    recipient_email_addresses = recipient_email_addresses_from_envelope(message.envelope)

    recipient_email_addresses.each do |recipient_email_address|
      account_email_data = fetch_account_email_data(recipient_email_address)
      next unless account_email_data.present? && not_blacklisted?(account_email_data[:email])

      record_email(message, account_list_id, account_email_data[:contact_id], account_email_data[:person_id], 'Done')
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

  def not_blacklisted?(email)
    return false unless email
    !blacklisted_domain?(email) && !blacklisted_emails.include?(email)
  end

  def blacklisted_domains
    @blacklisted_domains ||= begin
      blacklisted_emails.select { |email| email.starts_with?('*') }
                        .map { |domain| domain.split('@').last }
    end
  end

  def blacklisted_domain?(email)
    blacklisted_domains.include?(email.split('@').last)
  end

  def process_sent_emails(gmail, sent_mailbox, date)
    sent_uids = sent_mailbox.fetch_uids(on: date) || []
    process_each_message(sent_uids, sent_mailbox, gmail) do |gmail_message|
      record_sent_email(message: gmail_message)
    end
  end

  def process_received_emails(gmail, received_mailbox, date)
    received_uids = received_mailbox.fetch_uids(on: date) || []
    process_each_message(received_uids, received_mailbox, gmail) do |gmail_message|
      record_received_email(message: gmail_message)
    end
  end

  def process_each_message(uids, mailbox, gmail)
    uids.each_slice(20) do |uid_group|
      gmail.conn.uid_fetch(uid_group, Gmail::Message::PREFETCH_ATTRS).each do |imap_data|
        next unless imap_data

        gmail_message = Gmail::Message.new(mailbox, nil, imap_data)
        block_given? ? yield(gmail_message) : gmail_message
      end
    end
  end

  def create_task_for_contact(gmail_message, account_list_id, contact, result)
    contact.tasks.create!(subject: format_subject(gmail_message.subject),
                          start_at: gmail_message.envelope.date,
                          completed: true,
                          completed_at: gmail_message.envelope.date,
                          account_list_id: account_list_id,
                          activity_type: 'Email',
                          result: result,
                          remote_id: gmail_message.envelope.message_id,
                          source: 'gmail')
  end
end
