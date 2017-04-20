class AddReceivedNotProcessedToPledges < ActiveRecord::Migration
  def change
    add_column :pledges, :received_not_processed, :boolean
  end
end
