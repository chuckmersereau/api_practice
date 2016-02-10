class AddIndexToMasterAddressesCity < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :master_addresses, :city, algorithm: :concurrently
  end
end
