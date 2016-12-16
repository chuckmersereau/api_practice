class AddUuidToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :addresses, :uuid, unique: true
  end
end
