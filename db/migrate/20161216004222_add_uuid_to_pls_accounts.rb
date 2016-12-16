class AddUuidToPlsAccounts < ActiveRecord::Migration
  def change
    add_column :pls_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :pls_accounts, :uuid, unique: true
  end
end
