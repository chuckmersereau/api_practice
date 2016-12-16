class AddUuidToNicknames < ActiveRecord::Migration
  def change
    add_column :nicknames, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :nicknames, :uuid, unique: true
  end
end
