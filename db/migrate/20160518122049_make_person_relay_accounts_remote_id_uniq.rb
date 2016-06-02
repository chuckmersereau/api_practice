class MakePersonRelayAccountsRemoteIdUniq < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    execute 'create unique index concurrently person_relay_accounts_on_lower_remote_id
             on person_relay_accounts(lower(remote_id));'
  end
end
