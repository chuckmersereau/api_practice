class MasterAddress < ActiveRecord::Base
  has_many :addresses
  serialize :smarty_response, JSON

  def geo
    return nil unless latitude.present? && longitude.present?
    latitude + ',' + longitude
  end

  def self.populate_lat_long
    MasterAddress.where("latitude is null or latitude = ''").order('created_at desc').find_each do |ma|
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
        sleep 1 unless Rails.env.test?
      end
    end
  end
end
