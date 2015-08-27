require 'spec_helper'

describe MasterAddress do
  let!(:address) { create :master_address, latitude: '', longitude: nil }

  context '#geocode' do
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
      expect(address.geocode).to be_falsey
      expect(address.reload.latitude).to eq '12.3456'
    end
  end

  context 'populate_lat_long' do
    it 'geocodes master addresses that are missing latitude' do
      MasterAddress.populate_lat_long
      expect(address.reload.latitude).to be_present
    end
  end

  context 'find_timezone' do
    it 'geocodes first and returns nil if the latitude and longitude are missing' do
      expect(address).to receive(:geocode)
      expect(address.find_timezone).to be_nil
    end

    it 'fetches the timezone from Google using latitude and longitude' do
      timezone = double(time_zone_id: 'America/New_York')
      expect(GoogleTimezone).to receive(:fetch).with('40.7', '-74.0') { timezone }
      expect(address.find_timezone).to eq('Eastern Time (US & Canada)')
    end
  end
end
