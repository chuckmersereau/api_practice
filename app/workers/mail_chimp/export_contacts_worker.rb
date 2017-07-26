class MailChimp::ExportContactsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account, list_id, contact_ids)
    return if mail_chimp_account.primary_list_id == list_id

    MailChimp::Exporter.new(mail_chimp_account, list_id)
                       .export_contacts(contact_ids)
  end
end
