class RemoveActionsFromNotificationPreferences < ActiveRecord::Migration
  def change
    remove_column :notification_preferences, :actions
  end
end
