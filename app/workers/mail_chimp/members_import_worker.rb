class MailChimp::MembersImportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_mail_chimp_sync_worker, unique: :until_executed

  def perform(mail_chimp_account_id, _member_emails)
    mail_chimp_account = MailChimpAccount.find_by(id: mail_chimp_account_id)

    return unless mail_chimp_account

    # MailChimp::Importer.new(mail_chimp_account)
    # .import_members_by_email(member_emails)
  end
end
