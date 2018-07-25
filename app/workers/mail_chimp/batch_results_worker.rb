class MailChimp::BatchResultsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account_id, batch_id)
    mail_chimp_account = MailChimpAccount.find_by(id: mail_chimp_account_id)

    MailChimp::BatchResults.new(mail_chimp_account).check_batch(batch_id) if mail_chimp_account
  end
end
