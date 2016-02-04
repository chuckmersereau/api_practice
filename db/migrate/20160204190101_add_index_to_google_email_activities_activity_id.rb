class AddIndexToGoogleEmailActivitiesActivityId < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :google_email_activities, :activity_id, algorithm: :concurrently
  end
end
