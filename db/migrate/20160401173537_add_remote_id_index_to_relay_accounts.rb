class AddRemoteIdIndexToRelayAccounts < ActiveRecord::Migration
  def up
    execute 'create unique index index_remote_id_on_person_relay_account '\
            'on person_relay_accounts(lower(remote_id));'
  end

  def down
    execute 'drop index if exists index_remote_id_on_person_relay_account'
  end
end
