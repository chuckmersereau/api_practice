class AddIndexToActivitiesCompletedAt < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :activities, :completed_at, algorithm: :concurrently
  end
end
