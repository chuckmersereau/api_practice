class MailChimp::PrimaryListSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account)
    MailChimp::Syncer.new(mail_chimp_account).sync_with_primary_list
  end
end
