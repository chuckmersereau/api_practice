class MailChimp::PrimaryListSyncWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account_id)
    mail_chimp_account = MailChimpAccount.find_by(id: mail_chimp_account_id)

    return unless mail_chimp_account

    MailChimp::Syncer.new(mail_chimp_account).two_way_sync_with_primary_list
  end
end
