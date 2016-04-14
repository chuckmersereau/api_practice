class MailChimpAccount
  # This class contains code shared in common between AppealListHookHandler and
  # PrimaryListHookHandler, but it is not a fully functional hook handler in
  # itself.
  class BaseHookHandler
    def initialize(mail_chimp_account)
      @mc_account = mail_chimp_account
      @account_list = mail_chimp_account.account_list
    end

    def campaign_status_hook(campaign_id, status, subject)
      return unless status == 'sent'
      @mc_account.queue_log_sent_campaign(campaign_id, subject)
    end
  end
end
