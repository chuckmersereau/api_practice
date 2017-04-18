class AddIndexOnDonationsOnDesigDateRemote < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :donations,
              [:designation_account_id, :donation_date, :remote_id],
              name: 'index_donations_on_des_acc_id_and_don_date_and_rem_id',
              algorithm: :concurrently
  end
end
