class AddIndexToMasterAddressesCountry < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :master_addresses, :country, algorithm: :concurrently
  end
end
