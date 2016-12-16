class AddUuidToNotificationTypes < ActiveRecord::Migration
  def change
    add_column :notification_types, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :notification_types, :uuid, unique: true
  end
end
