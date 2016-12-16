class AddUuidToGoogleEmailActivities < ActiveRecord::Migration
  def change
    add_column :google_email_activities, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :google_email_activities, :uuid, unique: true
  end
end
