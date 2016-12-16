class AddUuidToAdminImpersonationLogs < ActiveRecord::Migration
  def change
    add_column :admin_impersonation_logs, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :admin_impersonation_logs, :uuid, unique: true
  end
end
