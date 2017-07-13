# This class handles the case where an email has bounced after it was sent by Mail Chimp.
class MailChimp::Webhook::Base
  class EmailBounceHandler
    def initialize(account_list, email, reason)
      @account_list = account_list
      @email = email
      @reason = reason
    end

    def handle_bounce
      emails_to_clean = EmailAddress.joins(person: [:contacts])
                                    .where(contacts: { account_list_id: @account_list.id }, email: @email)

      emails_to_clean.each do |email_to_clean|
        email_to_clean.update(historic: true, primary: false)

        SubscriberCleanedMailer.delay.subscriber_cleaned(@account_list, email_to_clean)
      end
    end
  end
end
