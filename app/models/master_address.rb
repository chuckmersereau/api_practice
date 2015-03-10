class MasterAddress < ActiveRecord::Base
  has_many :addresses
  serialize :smarty_response, JSON

  def geo
    if self.smarty_response && self.smarty_response[0] && self.smarty_response[0]['metadata']
      meta = master_address.smarty_response[0]['metadata']
      meta['latitude'].to_s + ',' + meta['longitude'].to_s
    else
      unless self.latitude && self.longitude
        lat, long = Geocoder.coordinates([self.street, self.city, self.state, self.country].join(','))
        self.latitude = lat.to_s
        self.longitude = long.to_s
        save
      end
      self.latitude + ',' + self.longitude
    end
  end
end
