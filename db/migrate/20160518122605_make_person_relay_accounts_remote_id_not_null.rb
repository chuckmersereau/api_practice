class MakePersonRelayAccountsRemoteIdNotNull < ActiveRecord::Migration
  def change
    change_column_null :person_relay_accounts, :remote_id, false
  end
end
