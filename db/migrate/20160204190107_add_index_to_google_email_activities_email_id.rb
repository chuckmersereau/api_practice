class AddIndexToGoogleEmailActivitiesEmailId < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :google_email_activities, :google_email_id, algorithm: :concurrently
  end
end
