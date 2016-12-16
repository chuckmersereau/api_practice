class AddUuidToFamilyRelationships < ActiveRecord::Migration
  def change
    add_column :family_relationships, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :family_relationships, :uuid, unique: true
  end
end
