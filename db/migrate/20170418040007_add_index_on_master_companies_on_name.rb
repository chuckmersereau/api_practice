class AddIndexOnMasterCompaniesOnName < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :master_companies, :name, algorithm: :concurrently
  end
end
