class AddIndexOnDonationsOnCreatedAt < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :donations, :created_at, algorithm: :concurrently
  end
end
