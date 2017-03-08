class CreateDesignationAccounts < ActiveRecord::Migration
  def change
    create_table :designation_accounts do |t|
      t.string :account_number
      t.string :account_source

      t.timestamps null: false
    end
  end
end
