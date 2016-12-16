class AddUuidToAdminResetLogs < ActiveRecord::Migration
  def change
    add_column :admin_reset_logs, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :admin_reset_logs, :uuid, unique: true
  end
end
