class RemoveDonationIdFromPledges < ActiveRecord::Migration
  def change
    remove_column :pledges, :donation_id, :integer
  end
end
