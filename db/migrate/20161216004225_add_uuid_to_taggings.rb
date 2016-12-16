class AddUuidToTaggings < ActiveRecord::Migration
  def change
    add_column :taggings, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :taggings, :uuid, unique: true
  end
end
