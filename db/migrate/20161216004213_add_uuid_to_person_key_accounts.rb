class AddUuidToPersonKeyAccounts < ActiveRecord::Migration
  def change
    add_column :person_key_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :person_key_accounts, :uuid, unique: true
  end
end
