class CreateAdminResetLogs < ActiveRecord::Migration
  def change
    create_table :admin_reset_logs do |t|
      t.integer :admin_resetting_id
      t.integer :resetted_user_id
      t.string :reason

      t.timestamps
    end
  end
end
