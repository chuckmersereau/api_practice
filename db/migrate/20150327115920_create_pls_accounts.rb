class CreatePlsAccounts < ActiveRecord::Migration
  def change
    create_table :pls_accounts do |t|
      t.integer :account_list_id
      t.string :oauth2_token
      t.boolean :valid_token, default: true, nil: false

      t.timestamps
    end

    add_index :pls_accounts, :account_list_id
    add_column :contacts, :pls_id, :string
  end
end
