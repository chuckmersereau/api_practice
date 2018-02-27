class AddUserIdToNotificationPreferences < ActiveRecord::Migration
  def change
    add_column :notification_preferences, :user_id, :integer
    add_foreign_key :notification_preferences, :people, dependent: :delete, column: :user_id
  end
end
