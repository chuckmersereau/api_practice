class RenamePersonRelayAccounts < ActiveRecord::Migration
  def up
    sql_query = <<~SQL
      DROP TABLE person_key_accounts;
      CREATE TABLE person_key_accounts (LIKE person_relay_accounts INCLUDING ALL);
      INSERT INTO person_key_accounts SELECT * FROM person_relay_accounts;
    SQL
    ActiveRecord::Base.connection.execute(sql_query)
  end

  def down; end
end
