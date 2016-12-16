class AddUuidToDesignationAccounts < ActiveRecord::Migration
  def change
    add_column :designation_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :designation_accounts, :uuid, unique: true
  end
end
