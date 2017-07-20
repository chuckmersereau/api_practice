class MailChimp::ExportContactsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account, list_id, contact_ids)
    MailChimp::Exporter.new(mail_chimp_account, list_id)
                       .export_to_appeal_list(contact_ids)
  end
end
