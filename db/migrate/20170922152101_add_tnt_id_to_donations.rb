class AddTntIdToDonations < ActiveRecord::Migration
  def change
    add_column :donations, :tnt_id, :string
    add_index :donations, :tnt_id
  end
end
