class AddUuidToMasterAddresses < ActiveRecord::Migration
  def change
    add_column :master_addresses, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :master_addresses, :uuid, unique: true
  end
end
