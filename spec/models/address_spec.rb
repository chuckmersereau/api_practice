require 'spec_helper'

describe Address do
  context '#find_master_address' do
    it 'normalized an address using smarty streets' do
      stub_request(:get, %r{https:\/\/api\.smartystreets\.com\/street-address})
        .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body:
          '[{"input_index":0,"candidate_index":0,"delivery_line_1":"12958 Fawns Dell Pl","last_line":"Fishers IN 46038-1026",'\
          '"delivery_point_barcode":"460381026587","components":{"primary_number":"12958","street_name":"Fawns Dell","street_suffix":"Pl",'\
          '"city_name":"Fishers","state_abbreviation":"IN","zipcode":"46038","plus4_code":"1026","delivery_point":"58","delivery_point_check_digit":"7"},'\
          '"metadata":{"record_type":"S","county_fips":"18057","county_name":"Hamilton","carrier_route":"C013","congressional_district":"05",'\
          '"rdi":"Residential","elot_sequence":"0006","elot_sort":"A","latitude":39.97531,"longitude":-86.02973,"precision":"Zip9"},'\
          '"analysis":{"dpv_match_code":"Y","dpv_footnotes":"AABB","dpv_cmra":"N","dpv_vacant":"N","active":"Y"}}]')
      address = build(:address)
      master_address = create(:master_address, street: '12958 fawns dell pl', city: 'fishers', state: 'in', country: 'united states', postal_code: '46038-1026')
      address.send(:find_master_address)
      address.master_address == master_address
    end
  end

  context '#clean_up_master_address' do
    it 'cleans up the master address when destroyed if it is no longer needed by others' do
      master = create(:master_address)
      address1 = create(:address, master_address: master)
      address2 = create(:address, master_address: master)
      expect {
        address1.destroy!
      }.to_not change(MasterAddress, :count).from(1)

      expect {
        address2.destroy!
      }.to change(MasterAddress, :count).from(1).to(0)
    end
  end

  context '#country=' do
    it 'normalizes the country when assigned' do
      address = build(:address)
      expect(Address).to receive(:normalize_country).with('USA').and_return('United States')
      address.country = 'USA'
      expect(address.country).to eq('United States')
    end
  end

  context '#normalize_country' do
    it 'returns passed in arg if given blank' do
      expect(Address.normalize_country('')).to eq('')
      expect(Address.normalize_country(nil)).to be_nil
    end

    it 'normalizes country by case' do
      expect(Address.normalize_country('united STATES')).to eq('United States')
    end

    it 'normalizes by alternate country name' do
      expect(Address.normalize_country('uSa')).to eq('United States')
    end

    it 'returns a country not in the list as is' do
      expect(Address.normalize_country('Some non-Existent country')).to eq('Some non-Existent country')
    end
  end

  context 'remote_id' do
    before(:each) do
      stub_request(:get, %r{https:\/\/api\.smartystreets\.com\/street-address})
          .with(headers: { 'Accept' => 'application/json', 'Accept-Encoding' => 'gzip, deflate', 'Content-Type' => 'application/json', 'User-Agent' => 'Ruby' })
          .to_return(status: 200, body: '[{"input_index":0,"candidate_index":0,"delivery_line_1":"12958 Fawns Dell Pl","last_line":"Fishers IN 46038-1026",'\
          '"delivery_point_barcode":"460381026587","components":{"primary_number":"12958","street_name":"Fawns Dell","street_suffix":"Pl",'\
          '"city_name":"Fishers","state_abbreviation":"IN","zipcode":"46038","plus4_code":"1026","delivery_point":"58","delivery_point_check_digit":"7"},'\
          '"metadata":{"record_type":"S","county_fips":"18057","county_name":"Hamilton","carrier_route":"C013","congressional_district":"05",'\
          '"rdi":"Residential","elot_sequence":"0006","elot_sort":"A","latitude":39.97531,"longitude":-86.02973,"precision":"Zip9"},'\
          '"analysis":{"dpv_match_code":"Y","dpv_footnotes":"AABB","dpv_cmra":"N","dpv_vacant":"N","active":"Y"}}]')
      @address = create(:address, remote_id: '1-QTp1E')
      @address.city = 'Amery'
    end

    it 'keeps remote id if user_changed is not set' do
      @address.save
      expect(@address.remote_id).to eq('1-QTp1E')
    end

    it 'sets remote_id to nil if user_changed is set' do
      @address.user_changed = true
      @address.save
      expect(@address.remote_id).to eq(nil)
    end
  end
end
