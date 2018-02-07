class ChangeActionsToBooleansOnNotificationPreferences < ActiveRecord::Migration
  def change
    add_column :notification_preferences, :email, :boolean, default: true
    add_column :notification_preferences, :task, :boolean, default: true
  end
end
