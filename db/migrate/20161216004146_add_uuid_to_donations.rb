class AddUuidToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :donations, :uuid, unique: true
  end
end
