class MailChimp::CampaignLoggerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account_id, campaign_id, subject)
    mail_chimp_account = MailChimpAccount.find_by(id: mail_chimp_account_id)

    return unless mail_chimp_account

    MailChimp::CampaignLogger.new(mail_chimp_account)
                             .log_sent_campaign(campaign_id, subject)
  end
end
