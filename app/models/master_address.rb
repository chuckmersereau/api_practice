class MasterAddress < ActiveRecord::Base
  has_many :addresses
  serialize :smarty_response, JSON

  def geo
    return nil unless latitude.present? && longitude.present?
    latitude + ',' + longitude
  end

  def self.populate_lat_long
    MasterAddress.where("latitude is null or latitude = ''")
      .order('created_at desc').find_each do |ma|
      ma.geocode
      sleep 1 unless Rails.env.test?
    end
  end

  def find_timezone
    geocode
    return unless latitude.present? && longitude.present?
    timezone = GoogleTimezone.fetch(latitude, longitude).time_zone_id
    ActiveSupport::TimeZone::MAPPING.invert[timezone]
  end

  def geocode
    if smarty_response && smarty_response[0] && smarty_response[0]['metadata']
      meta = smarty_response[0]['metadata']
      update!(latitude: meta['latitude'].to_s, longitude: meta['longitude'].to_s)
    end

    if longitude.blank? || latitude.blank?
      lat, long = Geocoder.coordinates([street, city, state, country].join(','))
      update!(latitude: lat.to_s, longitude: long.to_s)
    end
  end
end
