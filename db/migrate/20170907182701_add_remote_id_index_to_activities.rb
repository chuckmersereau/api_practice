class AddRemoteIdIndexToActivities < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :activities, :remote_id, algorithm: :concurrently
  end
end
