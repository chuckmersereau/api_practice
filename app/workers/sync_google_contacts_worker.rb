require 'async'

class SyncGoogleContactsWorker
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true

  def perform
    account_lists = AccountList.joins(:google_integrations)
                        .where(google_integrations: { contacts_integration: true })
    AsyncScheduler.schedule_over_24h(account_lists, :queue_sync_with_google_contacts)
  end
end
