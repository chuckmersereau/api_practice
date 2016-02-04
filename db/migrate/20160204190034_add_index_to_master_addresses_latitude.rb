class AddIndexToMasterAddressesLatitude < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :master_addresses, :latitude, algorithm: :concurrently
  end
end
