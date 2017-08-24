require 'rails_helper'

describe MasterAddress do
  let!(:address) { create :master_address, latitude: '', longitude: nil }

  describe 'scope requires_geocode' do
    it 'compares updated_at and last_geocoded_at ignoring milliseconds' do
      master_address_two = build(:master_address, latitude: nil, longitude: nil)
      master_address_two.last_geocoded_at = Time.current # last_geocoded_at and updated_at will have the same second, but different milliseconds.
      master_address_two.save!
      expect(MasterAddress.requires_geocode.ids).to eq([address.id])
    end
  end

  describe '#geocode' do
    it 'adds latitude and longitude' do
      expect(address.geocode).to be_truthy
      address.reload
      expect(address.latitude).to be_present
      expect(address.longitude).to be_present
    end

    it 'moves latitude from smarty to own field' do
      smarty_response = [
        { metadata: { latitude: 12.3456, longitude: -33.3333 } }
      ]
      address.update_attribute(:smarty_response, smarty_response)
      address.geocode
      expect(address.reload.latitude).to eq '12.3456'
    end

    it 'returns true if geocode took place' do
      address.last_geocoded_at = nil
      expect(address.geocode).to eq(true)
    end

    it 'returns false if geocode did not take place' do
      address.last_geocoded_at = address.updated_at + 1.hour
      expect(address.geocode).to eq(false)
    end

    it 'geocodes if last_geocoded_at is blank' do
      address.last_geocoded_at = nil
      address.geocode
      address.reload
      expect(address.latitude).to be_present
      expect(address.longitude).to be_present
      expect(address.last_geocoded_at.to_i).to eq(address.updated_at.to_i)
    end

    it 'geocodes if last_geocoded_at is less than updated_at' do
      address.last_geocoded_at = address.updated_at - 1.minute
      address.geocode
      address.reload
      expect(address.latitude).to be_present
      expect(address.longitude).to be_present
      expect(address.last_geocoded_at.to_i).to eq(address.updated_at.to_i)
    end

    it 'does not geocode if last_geocoded_at is greater than updated_at' do
      address.last_geocoded_at = address.updated_at + 1.minute
      expect { address.geocode && address.reload }.to_not change { address.last_geocoded_at }
      expect(address.latitude).to be_blank
      expect(address.longitude).to be_blank
    end

    it 'does not geocode if last_geocoded_at is equal to updated_at' do
      address.last_geocoded_at = address.updated_at
      expect { address.geocode && address.reload }.to_not change { address.last_geocoded_at }
      expect(address.latitude).to be_blank
      expect(address.longitude).to be_blank
    end
  end

  describe '.populate_lat_long' do
    it 'geocodes master addresses that are missing latitude' do
      MasterAddress.populate_lat_long
      expect(address.reload.latitude).to be_present
    end
  end

  describe '#find_timezone' do
    it 'geocodes first and returns nil if the latitude and longitude are missing' do
      expect(address).to receive(:geocode)
      expect(address.find_timezone).to be_nil
    end

    it 'fetches the timezone from Google using latitude and longitude' do
      timezone = double(time_zone_id: 'America/New_York')
      expect(GoogleTimezone).to receive(:fetch).with('40.7', '-74.0') { timezone }
      expect(address.find_timezone).to eq('Eastern Time (US & Canada)')
    end

    it 'returns the string of the timezone if not in ActiveSupport::TimeZone::MAPPING and valid' do
      timezone = double(time_zone_id: 'America/Vancouver')
      expect(GoogleTimezone).to receive(:fetch).with('40.7', '-74.0') { timezone }
      expect(address.find_timezone).to eq('America/Vancouver')
    end

    it 'returns the nil if not in ActiveSupport::TimeZone::MAPPING and invalid' do
      timezone = double(time_zone_id: 'NonExistantTimezone')
      expect(GoogleTimezone).to receive(:fetch).with('40.7', '-74.0') { timezone }
      expect(address.find_timezone).to be_nil
    end
  end
end
