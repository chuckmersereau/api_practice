class AddUuidToAccountLists < ActiveRecord::Migration
  def change
    add_column :account_lists, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :account_lists, :uuid, unique: true
  end
end
