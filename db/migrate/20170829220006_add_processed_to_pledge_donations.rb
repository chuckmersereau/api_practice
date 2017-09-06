class AddProcessedToPledgeDonations < ActiveRecord::Migration
  def change
    add_column :pledges, :processed, :boolean, default: false
  end
end
