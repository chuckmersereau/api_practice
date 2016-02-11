class AddIndexToMasterAddressesState < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :master_addresses, :state, algorithm: :concurrently
  end
end
