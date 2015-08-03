class CreateAccountListInvites < ActiveRecord::Migration
  def change
    create_table :account_list_invites do |t|
      t.belongs_to :account_list
      t.belongs_to :user
      t.string :code, null: false
      t.string :recipient_email, null: false
    end
  end
end
