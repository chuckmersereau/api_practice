class AddUuidToTags < ActiveRecord::Migration
  def change
    add_column :tags, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :tags, :uuid, unique: true
  end
end
