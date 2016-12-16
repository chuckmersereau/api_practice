class AddUuidToDonorAccounts < ActiveRecord::Migration
  def change
    add_column :donor_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :donor_accounts, :uuid, unique: true
  end
end
