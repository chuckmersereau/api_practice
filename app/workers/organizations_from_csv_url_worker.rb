class OrganizationsFromCsvUrlWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_organizations_from_csv_url_worker, unique: :until_executed

  def perform(url)
    # Download the org csv from tnt and update orgs
    organizations_csv = open(url).read.unpack('C*').pack('U*')
    CSV.new(organizations_csv, headers: :first_row).each do |line|
      name, url = line[0..1]
      next unless url.present?
      OrganizationFromQueryUrlWorker.perform(name, url)
    end
  end
end
