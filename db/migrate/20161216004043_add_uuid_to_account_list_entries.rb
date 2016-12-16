class AddUuidToAccountListEntries < ActiveRecord::Migration
  def change
    add_column :account_list_entries, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :account_list_entries, :uuid, unique: true
  end
end
