class SidekiqCronLoader
  SIDEKIQ_CRON_HASH = {
    'TaskNotificationsWorker' => {
      'class' => 'TaskNotificationsWorker',
      'cron'  => '0 * * * *',
      'args'  => []
    },

    'GoogleEmailSyncEnqueuerWorker' => {
      'class' => 'GoogleEmailSyncEnqueuerWorker',
      'cron'  => '1 7 * * *',
      'args'  => []
    },

    'AccountListImportDataEnqueuerWorker' => {
      'class' => 'AccountListImportDataEnqueuerWorker',
      'cron'  => '2 7 * * *',
      'args'  => []
    },

    'Populate Lat/Lon' => {
      'class' => 'SidekiqCronWorker',
      'cron'  => '3 7 * * *',
      'args'  => ['MasterAddress.populate_lat_long']
    },

    'OrganizationFetcherWorker' => {
      'class' => 'OrganizationFetcherWorker',
      'cron'  => '4 7 * * *',
      'args'  => []
    },

    'Clear Stalled Downloads' => {
      'class' => 'SidekiqCronWorker',
      'cron'  => '5 7 * * *',
      'args'  => ['Person::OrganizationAccount.clear_stalled_downloads']
    },

    'CurrencyRatesFetcherWorker' => {
      'class' => 'CurrencyRatesFetcherWorker',
      'cron'  => '6 7 * * *',
      'args'  => []
    },

    'GoogleContactsSyncEnqueuerWorker' => {
      'class' => 'GoogleContactsSyncEnqueuerWorker',
      'cron'  => '7 7 * * *',
      'args'  => []
    }
  }.freeze

  def load
    return if !Rails.env.production? || precompiling_assets? || running_console?
    load!
  end

  def load!
    Sidekiq::Cron::Job.load_from_hash!(SIDEKIQ_CRON_HASH)
  end

  private

  def precompiling_assets?
    ARGV.any? { |e| e =~ /\Aassets:.+/ }
  end

  def running_console?
    defined?(Rails::Console)
  end
end
