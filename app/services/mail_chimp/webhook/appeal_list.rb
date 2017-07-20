# This class holds all the methods associated to the Mail Chimp webhooks that are linked to an appeal list.
module MailChimp::Webhook
  class AppealList < Base
    def subscribe_hook(email)
      # This will have to be implemented one day
    end

    def unsubscribe_hook(email)
      # This will have to be implemented one day
    end

    def email_update_hook(old_email, new_email)
      # This will have to be implemented one day
    end

    def email_cleaned_hook(email, reason)
      return if reason == 'abuse'

      EmailBounceHandler.new(@account_list, email, reason).handle_bounce
    end
  end
end
