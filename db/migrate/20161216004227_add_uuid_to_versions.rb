class AddUuidToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :versions, :uuid, unique: true
  end
end
