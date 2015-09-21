class AddCancelledByUserToAccountListInvites < ActiveRecord::Migration
  def change
    add_column :account_list_invites, :cancelled_by_user_id, :integer
  end
end
