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

      # Force update of the master address
      address.master_address_id = nil
      address.send(:determine_master_address)

      expect(address.master_address).to eq(master_address)
    end
  end

  context '#clean_up_master_address' do
    it 'cleans up the master address when destroyed if it is no longer needed by others' do
      master = create(:master_address)
      address1 = create(:address, master_address: master)
      address2 = create(:address, master_address: master)
      expect do
        address1.destroy!
      end.to_not change(MasterAddress, :count).from(1)

      expect do
        address2.destroy!
      end.to change(MasterAddress, :count).from(1).to(0)
    end
  end

  context '#destroy' do
    it 'clears the primary mailing address flag when destroyed' do
      address1 = create(:address, primary_mailing_address: true)
      address1.destroy
      expect(address1.primary_mailing_address).to be false
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
    it 'normalizes country by case' do
      expect(Address.normalize_country('united STATES')).to eq('United States')
    end

    it 'normalizes by alternate country name' do
      expect(Address.normalize_country('uSa')).to eq('United States')
    end

    it 'returns a country not in the list as is' do
      expect(Address.normalize_country('Some non-Existent country')).to eq('Some non-Existent country')
    end

    it 'strips white space out from input' do
      expect(Address.normalize_country(' united STATES ')).to eq('United States')
    end

    it 'strips white space out if country not in list' do
      expect(Address.normalize_country(' Not-A-Country  ')).to eq('Not-A-Country')
    end

    it 'returns nil for nil' do
      expect(Address.normalize_country(nil)).to be_nil
    end

    it 'returns nil for blank space' do
      expect(Address.normalize_country('   ')).to be_nil
    end
  end

  context '#merge' do
    let(:a1) { create(:address, start_date: Date.new(2014, 1, 1)) }
    let(:a2) { create(:address, start_date: Date.new(2014, 1, 2)) }

    describe 'takes the min first start_date of the two addresses' do
      it 'works with a1 winner' do
        a1.merge(a2)
        expect(a1.start_date).to eq(Date.new(2014, 1, 1))
      end
      it 'works with a2 winner' do
        a2.merge(a1)
        expect(a2.start_date).to eq(Date.new(2014, 1, 1))
      end
    end

    it 'takes the non-nil start date if only one specified' do
      a1.update(start_date: nil)
      a1.merge(a2)
      expect(a1.start_date).to eq(Date.new(2014, 1, 2))
    end

    it 'sets source to Siebel if remote_id specified' do
      a2.remote_id = 'a'
      a1.update(source: 'not-siebel')
      a1.merge(a2)
      expect(a1.source).to eq('Siebel')
    end

    it 'takes the non-nil source by default' do
      a2.update(source: 'import')
      a1.merge(a2)
      expect(a1.source).to eq('import')
    end

    it 'taks the non-nil source_donor_account' do
      donor_account = create(:donor_account)
      a2.source_donor_account = donor_account
      a1.merge(a2)
      expect(a1.source_donor_account).to eq(donor_account)
    end
  end

  describe 'start_date and manual source behavior' do
    it 'sets source to manual and start_date to today for a new user changed address' do
      address = build(:address, user_changed: true)
      address.save
      expect(address.start_date).to eq(Date.today)
      expect(address.source).to eq(Address::MANUAL_SOURCE)
    end

    it 'does not update start_date for a user changed when only address meta data is updated' do
      da = create(:donor_account)
      start = Date.new(2014, 1, 15)
      a = Address.create(start_date: start, source: 'import', source_donor_account: da)
      a.update(seasonal: true, primary_mailing_address: true, remote_id: '5', master_address_id: 2,
               location: 'Other', user_changed: true)
      expect(a.start_date).to eq(start)
      expect(a.source).to eq('import')
      expect(a.source_donor_account).to eq(da)
    end

    it 'updates to today for a user changed address when place attributes change' do
      da = create(:donor_account)
      [:street, :city, :state, :postal_code, :country].each do |field|
        a = Address.create(start_date: Date.new(2014, 1, 15), source: 'import', source_donor_account: da)
        a.update(field => 'not-nil', user_changed: true)
        expect(a.start_date).to eq(Date.today)
        expect(a.source).to eq(Address::MANUAL_SOURCE)
        expect(a.source_donor_account).to be_nil
      end
    end

    it 'does not update start date or source for non-user changed address when place attributes change' do
      start = Date.new(2014, 1, 15)
      [:street, :city, :state, :postal_code, :country].each do |field|
        a = Address.create(source: 'import', start_date: start)
        a.update(field => 'a')
        expect(a.start_date).to eq(start)
        expect(a.source).to eq('import')
      end
    end

    it 'does not update start date and source for changes affecting only whitespace or nil to blank' do
      start = Date.new(2014, 1, 15)
      [:street, :city, :state, :postal_code, :country].each do |field|
        # rubocop:disable DuplicatedKey
        { nil => '', ' a ' => 'a', ' ' => nil, nil => ' ', 'b' => ' b ' }.each do |from_val, to_val|
          a = Address.create(source: 'import', start_date: start, field => from_val)
          a.update(field => to_val, user_changed: true)
          expect(a.start_date).to eq(start)
          expect(a.source).to eq('import')
        end
      end
    end
  end

  context '#csv_street' do
    it 'normalizes newlines and strips whitespace' do
      address = build(:address, street: "123 Somewhere\r\n#1\n")
      expect(address.csv_street).to eq("123 Somewhere\n#1")
    end

    it 'gives nil for nil' do
      expect(build(:address, street: nil).csv_street).to be_nil
    end
  end

  context '#csv_country' do
    let(:address) { create(:address, country: 'Test Country') }

    it 'returns blank when the passed in country equals the address country' do
      expect(address.csv_country('Test Country')).to eq('')
    end

    it 'returns the country when none is passed in' do
      expect(address.csv_country('')).to eq(address.country)
    end
  end

  describe 'paper trail version logic', versioning: true do
    it 'tracks destroys' do
      donor_account = create(:donor_account)
      donor_account.addresses << create(:address, addressable: donor_account)
      donor_account.addresses.reload.first.mark_for_destruction

      expect do
        donor_account.save
      end.to change(Version, :count).by_at_least(1)

      expect(Version.last.event).to eq 'destroy'
      expect(Version.last.item_type).to eq 'Address'
    end

    it 'tracks address creates' do
      expect do
        create(:address)
      end.to change(Version, :count).by(1)

      expect(Version.last.event).to eq 'create'
      expect(Version.last.item_type).to eq 'Address'
    end

    it 'does not tracks updates if account list not logging debug info' do
      stub_smarty_streets
      account_list = create(:account_list, log_debug_info: nil)
      contact = create(:contact, account_list: account_list)
      address = create(:address, street: '1 St', addressable: contact)

      expect do
        address.reload.update(street: '2 St')
      end.to_not change(Version, :count)
    end

    it 'tracks updates if account list logging debug info' do
      stub_smarty_streets
      account_list = create(:account_list, log_debug_info: true)
      contact = create(:contact, account_list: account_list)
      address = create(:address, street: '1 St', addressable: contact)

      expect do
        address.reload.update(street: '2 St')
      end.to change(Version, :count).by(1)

      expect(Version.last.event).to eq 'update'
      expect(Version.last.item_type).to eq 'Address'
    end

    it 'does not track donor account address updates' do
      stub_smarty_streets
      donor_account = create(:donor_account)
      address = create(:address, street: '1 St', addressable: donor_account)

      expect do
        address.reload.update(street: '2 St')
      end.to_not change(Version, :count)
    end
  end
end
