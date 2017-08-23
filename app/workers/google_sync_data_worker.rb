class GoogleSyncDataWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_sync_data_worker, unique: :until_executed

  def perform(google_integration_id, integration)
    begin
      google_integration = GoogleIntegration.find(google_integration_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    google_integration.sync_data(integration)
  end
end
