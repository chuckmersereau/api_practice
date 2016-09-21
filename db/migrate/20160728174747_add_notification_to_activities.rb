class AddNotificationToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :notification_type, :integer
    add_column :activities, :notification_time_before, :integer
    add_column :activities, :notification_time_unit, :integer
    add_column :activities, :notification_scheduled, :boolean
  end
end
