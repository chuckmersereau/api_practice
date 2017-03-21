class RemoveRemoteIdNotNullConstraintFromPersonLinkedinAccounts < ActiveRecord::Migration
  def up
    change_column :person_linkedin_accounts, :remote_id, :string, null: true
  end

  def down
    change_column :person_linkedin_accounts, :remote_id, :string, null: false
  end
end
