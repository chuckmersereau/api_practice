class GoogleContactsSyncEnqueuerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_contacts_sync_enqueuer_worker, unique: :until_executed

  def perform
    AccountList.joins(:google_integrations).where(google_integrations: { contacts_integration: true }).find_each(&:queue_sync_with_google_contacts)
  end
end
