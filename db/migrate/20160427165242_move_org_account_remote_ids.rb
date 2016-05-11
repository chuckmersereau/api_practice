class MoveOrgAccountRemoteIds < ActiveRecord::Migration
  def change
    rename_column :person_relay_accounts, :remote_id, :relay_remote_id
    rename_column :person_relay_accounts, :key_remote_id, :remote_id
  end
end
