class AddCompletedAtToAdminResetLog < ActiveRecord::Migration
  def change
    add_column :admin_reset_logs, :completed_at, :datetime
  end
end
