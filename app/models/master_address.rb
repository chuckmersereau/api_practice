class MasterAddress < ActiveRecord::Base
  has_many :addresses
  serialize :smarty_response, JSON

  def geo
    if smarty_response && smarty_response[0] && smarty_response[0]['metadata']
      meta = smarty_response[0]['metadata']
      meta['latitude'].to_s + ',' + meta['longitude'].to_s
    else
      unless latitude && longitude
        lat, long = Geocoder.coordinates([street, city, state, country].join(','))
        self.latitude = lat.to_s
        self.longitude = long.to_s
        save
      end
      latitude + ',' + longitude
    end
  end
end
