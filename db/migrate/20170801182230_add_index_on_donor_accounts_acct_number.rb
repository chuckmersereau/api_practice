class AddIndexOnDonorAccountsAcctNumber < ActiveRecord::Migration
  disable_ddl_transaction!

  def self.up
    execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
    execute 'CREATE INDEX concurrently index_donor_accounts_on_acct_num_trig ON donor_accounts USING GIN (account_number gin_trgm_ops);'
  end

  def self.down
    remove_index :donor_accounts, name: :index_donor_accounts_on_acct_num_trig, algorithm: :concurrently
    execute 'DROP EXTENSION IF EXISTS pg_trgm;'
  end
end
