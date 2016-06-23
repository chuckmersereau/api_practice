class SyncGoogleContactsWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    AccountList.joins(:google_integrations)
         .where(google_integrations: { contacts_integration: true })
         .find_each(&:queue_sync_with_google_contacts)
  end
end
