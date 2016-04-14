class MailChimpAccount
  class AppealListHookHandler < BaseHookHandler
    def subscribe_hook(email)
    end

    def unsubscribe_hook(email)
    end

    def email_update_hook(old_email, new_email)
    end

    def email_cleaned_hook(email, reason)
      return if reason == 'abuse'
      EmailBounceHandler.new(@account_list, email, reason).handle_bounce
    end
  end
end
