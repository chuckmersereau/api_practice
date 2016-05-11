class AddKeyRemoteIdToPersonRelayAccount < ActiveRecord::Migration
  def change
    add_column :person_relay_accounts, :key_remote_id, :string
  end
end
