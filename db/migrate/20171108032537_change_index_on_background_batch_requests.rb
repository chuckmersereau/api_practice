class ChangeIndexOnBackgroundBatchRequests < ActiveRecord::Migration
  def change
    remove_index :background_batch_requests, :uuid
    add_index :background_batch_requests, :uuid, unique: true
  end
end
