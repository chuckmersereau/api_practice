class CreateMailChimpMembers < ActiveRecord::Migration
  def change
    create_table :mail_chimp_members do |t|
      t.integer :mail_chimp_account_id, null: false
      t.string :list_id, null: false
      t.string :email, null: false
      t.string :status
      t.string :greeting
      t.string :first_name
      t.string :last_name

      t.timestamps
    end

    add_index :mail_chimp_members, :mail_chimp_account_id
    add_index :mail_chimp_members, :list_id
    add_index :mail_chimp_members, :email
    add_index :mail_chimp_members, [:mail_chimp_account_id, :list_id, :email], unique: true
  end
end
