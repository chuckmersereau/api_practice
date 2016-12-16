class AddUuidToContactDonorAccounts < ActiveRecord::Migration
  def change
    add_column :contact_donor_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :contact_donor_accounts, :uuid, unique: true
  end
end
