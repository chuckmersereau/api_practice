class AddValidValuesIndexes < ActiveRecord::Migration
  def change
    add_index :contacts, :status_valid
    add_index :addresses, :valid_values
    add_index :phone_numbers, :valid_values
    add_index :email_addresses, :valid_values
    add_index :addresses, :source
    add_index :phone_numbers, :source
    add_index :email_addresses, :source
  end
end
