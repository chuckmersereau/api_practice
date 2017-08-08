# Webhooks are calls to the MPDX API made by Mail Chimp following certain events.
# These calls are received by the mail_chimp_webhook_controller and handled by
# different classes in the mail_chimp/webhook folder.
# This class is inherited by all webhook service classes and therefore implements
# methods that every single webhook class should implement.
module MailChimp::Webhook
  class Base
    attr_reader :mail_chimp_account, :account_list

    def initialize(mail_chimp_account)
      @mail_chimp_account = mail_chimp_account
      @account_list = mail_chimp_account.account_list
    end

    def campaign_status_hook(campaign_id, status, subject)
      return unless status == 'sent'

      mail_chimp_account.update(prayer_letter_last_sent: Time.current)
      MailChimp::CampaignLoggerWorker.perform_async(mail_chimp_account.id, campaign_id, subject)
    end
  end
end
