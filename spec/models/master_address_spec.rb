require 'spec_helper'

describe MasterAddress do
  context '#populate_lat_long' do
    let!(:address) { create :master_address, latitude: '' }
    it 'adds latitude' do
      expect do
        MasterAddress.populate_lat_long
      end.to change { address.reload.latitude }
    end

    it 'moves latitude from smarty to own field' do
      smarty_response = [
        { metadata: { latitude: 12.3456, longitude: -33.3333 } }
      ]
      address.update_attribute(:smarty_response, smarty_response)
      MasterAddress.populate_lat_long
      expect(address.reload.latitude).to eq '12.3456'
    end
  end
end
