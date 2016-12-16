class AddUuidToMessages < ActiveRecord::Migration
  def change
    add_column :messages, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :messages, :uuid, unique: true
  end
end
