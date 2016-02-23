class CreateAdminImpersonationLog < ActiveRecord::Migration
  def change
    create_table :admin_impersonation_logs do |t|
      t.text :reason, null: false
      t.integer :impersonator_id, null: false
      t.integer :impersonated_id, null: false
      t.timestamps
    end
  end
end
