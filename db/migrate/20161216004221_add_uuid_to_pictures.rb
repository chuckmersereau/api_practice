class AddUuidToPictures < ActiveRecord::Migration
  def change
    add_column :pictures, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :pictures, :uuid, unique: true
  end
end
