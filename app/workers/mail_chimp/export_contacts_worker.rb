class MailChimp::ExportContactsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account_id, list_id, contact_ids, ignore_status = false)
    mail_chimp_account = MailChimpAccount.find_by(id: mail_chimp_account_id)

    return unless mail_chimp_account

    MailChimp::Exporter.new(mail_chimp_account, list_id)
                       .export_contacts(contact_ids, ignore_status)
  end
end
