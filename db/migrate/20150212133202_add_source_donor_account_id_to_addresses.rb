class AddSourceDonorAccountIdToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :source_donor_account_id, :integer
  end
end
