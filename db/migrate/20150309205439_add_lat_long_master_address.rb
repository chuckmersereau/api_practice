class AddLatLongMasterAddress < ActiveRecord::Migration
  def change
    add_column :master_addresses, :latitude, :string
    add_column :master_addresses, :longitude, :string

    MasterAddress.find_each do |ma|
      if ma.smarty_response && ma.smarty_response[0] && ma.smarty_response[0]['metadata']
        meta = ma.smarty_response[0]['metadata']
        ma.latitude = meta['latitude'].to_s
        ma.longitude = meta['longitude'].to_s
        ma.save
      end

      if ma.longitude.blank? || ma.latitude.blank?
        lat, long = Geocoder.coordinates([ma.street, ma.city, ma.state, ma.country].join(','))
        ma.latitude = lat.to_s
        ma.longitude = long.to_s
        ma.save
      end
    end
  end
end
