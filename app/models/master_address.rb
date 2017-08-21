class MasterAddress < ApplicationRecord
  has_many :addresses
  serialize :smarty_response, JSON

  scope :requires_geocode, -> { where("latitude IS NULL OR latitude = ''").where('updated_at::timestamp(0) > last_geocoded_at::timestamp(0) OR last_geocoded_at IS NULL') }

  def geo
    return unless latitude.present? && longitude.present?
    latitude + ',' + longitude
  end

  def self.populate_lat_long
    requires_geocode.find_each do |master_address|
      next unless master_address.geocode
      sleep 0.1
    end
  end

  def find_timezone
    geocode
    return unless latitude.present? && longitude.present?
    timezone = GoogleTimezone.fetch(latitude, longitude).time_zone_id
    ActiveSupport::TimeZone::MAPPING.invert[timezone]
  end

  def geocode
    return false unless requires_geocode?

    assign_lat_long_from_smarty_response
    assign_lat_long_from_geocoder if longitude.blank? || latitude.blank?
    self.last_geocoded_at = Time.current
    save

    true
  end

  private

  def requires_geocode?
    return false if latitude.present? && longitude.present?
    return true if last_geocoded_at.blank?
    updated_at.to_i > last_geocoded_at.to_i
  end

  def assign_lat_long_from_smarty_response
    return unless smarty_response && smarty_response[0] && smarty_response[0]['metadata']
    meta = smarty_response[0]['metadata']
    self.latitude = meta['latitude'].to_s
    self.longitude = meta['longitude'].to_s
  end

  def assign_lat_long_from_geocoder
    lat, long = Geocoder.coordinates([street, city, state, country].join(','))
    self.latitude = lat.to_s
    self.longitude = long.to_s
  end
end
