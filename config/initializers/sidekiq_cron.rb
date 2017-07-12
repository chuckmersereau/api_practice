SIDEKIQ_CRON_HASH = {

  'Task Notifications' => {
    'class' => 'TaskNotificationsWorker',
    'cron'  => '0 * * * *',
    'args'  => []
  },

  'GoogleEmailSyncSchedulerWorker' => {
    'class' => 'GoogleEmailSyncSchedulerWorker',
    'cron'  => '0 3 * * *',
    'args'  => []
  },

  'Donations download' => {
    'class' => 'SidekiqCronWorker',
    'cron'  => '0 5 * * *',
    'args'  => ['AccountList.update_linked_org_accounts']
  },

  'Populate Lat/Lon' => {
    'class' => 'SidekiqCronWorker',
    'cron'  => '0 7 * * *',
    'args'  => ['MasterAddress.populate_lat_long']
  },

  'Fetch organizations' => {
    'class' => 'OrganizationFetcherWorker',
    'cron'  => '0 10 * * *',
    'args'  => []
  },

  'Clear stalled downloads' => {
    'class' => 'SidekiqCronWorker',
    'cron'  => '0 10 * * *',
    'args'  => ['Person::OrganizationAccount.clear_stalled_downloads']
  },

  'Mailchimp sync' => {
    'class' => 'MailChimpSyncWorker',
    'cron'  => '0 10 * * *',
    'args'  => []
  },

  'Fetch currency rates' => {
    'class' => 'CurrencyRatesFetcherWorker',
    'cron' => '0 11 * * *',
    'args' => []
  },

  'Refresh facebook tokens' => {
    'class' => 'SidekiqCronWorker',
    'cron'  => '0 11 * * *',
    'args'  => ['Person::FacebookAccount.refresh_tokens']
  },

  'Sync Google Contacts' => {
      'class' => 'SyncGoogleContactsWorker',
      'cron'  => '0 11 * * *',
      'args'  => []
  }
}.freeze

def load_sidekiq_cron_hash
  Sidekiq::Cron::Job.load_from_hash! SIDEKIQ_CRON_HASH
end

def precompiling_assets?
  ARGV.any? { |e| e =~ /\Aassets:.+/ }
end

def running_console?
  defined?(Rails::Console)
end

load_sidekiq_cron_hash if Rails.env.production? && !precompiling_assets? &&
                          !running_console?
