class AddInviteUserAsToAccountListInvites < ActiveRecord::Migration
  def change
    add_column :account_list_invites, :invite_user_as, :string, default: 'user'
  end
end
