class AddLatLongMasterAddress < ActiveRecord::Migration
  def change
    add_column :master_addresses, :latitude, :string
    add_column :master_addresses, :longitude, :string
  end
end
