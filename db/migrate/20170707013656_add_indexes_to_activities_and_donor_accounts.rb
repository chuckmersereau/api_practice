class AddIndexesToActivitiesAndDonorAccounts < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    remove_index :activities,
                 column: :account_list_id,
                 name: :index_activities_on_account_list_id,
                 algorithm: :concurrently

    add_index :donor_accounts,
              :account_number,
              name: 'index_donor_accounts_on_account_number',
              algorithm: :concurrently

    add_index :activities,
              [:account_list_id, :completed],
              name: 'activities_on_list_id_completed',
              algorithm: :concurrently
  end
end
