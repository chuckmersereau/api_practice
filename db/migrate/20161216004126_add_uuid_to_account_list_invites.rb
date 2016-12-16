class AddUuidToAccountListInvites < ActiveRecord::Migration
  def change
    add_column :account_list_invites, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :account_list_invites, :uuid, unique: true
  end
end
