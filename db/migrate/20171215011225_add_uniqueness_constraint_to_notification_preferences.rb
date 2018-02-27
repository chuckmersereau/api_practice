class AddUniquenessConstraintToNotificationPreferences < ActiveRecord::Migration
  def change
    add_index :notification_preferences,
              [:user_id, :account_list_id, :notification_type_id],
              name: 'index_notification_preferences_unique',
              unique: true
  end
end
