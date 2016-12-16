class AddUuidToMasterPersonDonorAccounts < ActiveRecord::Migration
  def change
    add_column :master_person_donor_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :master_person_donor_accounts, :uuid, unique: true
  end
end
