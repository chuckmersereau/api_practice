class AddUuidToNotificationPreferences < ActiveRecord::Migration
  def change
    add_column :notification_preferences, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :notification_preferences, :uuid, unique: true
  end
end
