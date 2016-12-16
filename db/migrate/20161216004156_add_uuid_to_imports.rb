class AddUuidToImports < ActiveRecord::Migration
  def change
    add_column :imports, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :imports, :uuid, unique: true
  end
end
