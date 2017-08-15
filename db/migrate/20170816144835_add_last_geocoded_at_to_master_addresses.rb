class AddLastGeocodedAtToMasterAddresses < ActiveRecord::Migration
  def change
    add_column :master_addresses, :last_geocoded_at, :datetime
  end
end
