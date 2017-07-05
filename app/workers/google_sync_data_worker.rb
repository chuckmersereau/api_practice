class GoogleSyncDataWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_sync_data_worker

  def perform(google_integration_id, integration)
    GoogleIntegration.find(google_integration_id).sync_data(integration)
  end
end
