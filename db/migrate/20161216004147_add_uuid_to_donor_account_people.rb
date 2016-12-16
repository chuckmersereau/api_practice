class AddUuidToDonorAccountPeople < ActiveRecord::Migration
  def change
    add_column :donor_account_people, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :donor_account_people, :uuid, unique: true
  end
end
