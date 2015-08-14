# encoding: utf-8
require 'open-uri'
require 'csv'

namespace :organizations do
  task fetch: :environment do
    OrganizationFetcherWorker.new.perform
  end
end
