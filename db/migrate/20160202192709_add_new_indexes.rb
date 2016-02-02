class AddNewIndexes < ActiveRecord::Migration
  def change
    add_index :master_addresses, :postal_code
    add_index :activities, :completed
    execute "create index index_addresses_on_lower_city
             on addresses(lower(city));"
  end
end
