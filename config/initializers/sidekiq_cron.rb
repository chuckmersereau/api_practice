SIDEKIQ_CRON_HASH  = {
  'Google email sync' => {
    'class' => 'SidekiqCronWorker',
    'cron'  => '0 3 * * *',
    'args'  => ['GoogleIntegration.sync_all_email_accounts']
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
  }
}

def load_sidekiq_cron_hash
  Sidekiq::Cron::Job.load_from_hash! SIDEKIQ_CRON_HASH
end

load_sidekiq_cron_hash if Rails.env.production?
