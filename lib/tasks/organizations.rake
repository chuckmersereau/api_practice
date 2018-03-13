require 'open-uri'
require 'csv'

namespace :organizations do
  task fetch: :environment do
    OrganizationsFromCsvUrlWorker.new.perform(
      'https://download.tntware.com/tntconnect/TntConnect_Organizations.csv'
    )
  end
end
