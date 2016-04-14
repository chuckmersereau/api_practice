class AddCountryToOrganization < ActiveRecord::Migration
  def up
    add_column :organizations, :country, :string
    fetcher = OrganizationFetcherWorker.new
    Organization.all.each do |org|
      country = fetcher.guess_country(org.name)
      org.update(country: country) if country
    end
  end

  def down
    remove_column :organizations, :country
  end
end
