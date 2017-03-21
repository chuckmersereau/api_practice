class RemoveNotNullConstraintFromRemoteIdOnPersonTwitterAccounts < ActiveRecord::Migration
  def up
    change_column :person_twitter_accounts, :remote_id, :bigint, null: true
  end

  def down
    change_column :person_twitter_accounts, :remote_id, :bigint, null: false
  end
end
