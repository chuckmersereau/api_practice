class AddIndexOnContactsStatus < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :contacts, :status, algorithm: :concurrently
  end
end
