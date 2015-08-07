class CreateAccountListInvites < ActiveRecord::Migration
  def change
    create_table :account_list_invites do |t|
      t.belongs_to :account_list
      t.integer :invited_by_user_id, null: false
      t.string :code, null: false
      t.string :recipient_email, null: false
      t.integer :accepted_by_user_id
      t.datetime :accepted_at
    end
  end
end
