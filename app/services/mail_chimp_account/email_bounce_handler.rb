class MailChimpAccount
  class EmailBounceHandler
    def initialize(account_list, email, reason)
      @account_list = account_list
      @email = email
      @reason = reason
    end

    def handle_bounce
      emails = EmailAddress.joins(person: [:contacts])
                           .where(contacts: { account_list_id: @account_list.id }, email: @email)

      emails.each do |email_to_clean|
        email_to_clean.update(historic: true, primary: false)
        SubscriberCleanedMailer.delay.subscriber_cleaned(@account_list, email_to_clean)
      end
    end
  end
end
