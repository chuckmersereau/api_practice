class AddUuidToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :organizations, :uuid, unique: true
  end
end
