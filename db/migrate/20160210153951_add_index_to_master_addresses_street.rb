class AddIndexToMasterAddressesStreet < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :master_addresses, :street, algorithm: :concurrently
  end
end
