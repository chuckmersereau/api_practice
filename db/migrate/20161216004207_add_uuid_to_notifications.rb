class AddUuidToNotifications < ActiveRecord::Migration
  def change
    add_column :notifications, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :notifications, :uuid, unique: true
  end
end
