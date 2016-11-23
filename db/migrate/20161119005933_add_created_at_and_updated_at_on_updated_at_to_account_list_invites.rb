class AddCreatedAtAndUpdatedAtOnUpdatedAtToAccountListInvites < ActiveRecord::Migration
  def change
    add_column :account_list_invites, :created_at, :datetime
    add_column :account_list_invites, :updated_at, :datetime
  end
end
