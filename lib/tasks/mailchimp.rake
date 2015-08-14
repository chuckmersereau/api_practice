namespace :mailchimp do
  desc 'Sync MPDX users to mailchimp list'
  task sync: :environment do
    MailChimpSyncWorker.new.perform
  end
end
