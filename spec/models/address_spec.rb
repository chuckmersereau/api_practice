# encoding: utf-8
require 'rails_helper'

describe Address do
  context 'validates updatable_only_when_source_is_mpdx' do
    before { stub_smarty_streets }
    include_examples 'updatable_only_when_source_is_mpdx_validation_examples',
                     attributes: [:street, :city, :state, :country, :postal_code, :start_date, :end_date, :remote_id, :region, :metro_area],
                     factory_type: :address
  end

  include_examples 'before_create_set_valid_values_based_on_source_examples', factory_type: :address
  include_examples 'after_validate_set_source_to_mpdx_examples', factory_type: :address

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

    it 'it has the "MPDX" source by default' do
      expect(a1.source).to eq('MPDX')
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
        a.update!(field => 'not-nil', user_changed: true)
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

  context '#equal_to?' do
    it 'matches addresses that share a master_address_id' do
      a1 = build(:address, street: '1 Rd', master_address_id: 1)
      a2 = build(:address, street: '1 Road', master_address_id: 1)

      expect(a1).to be_equal_to a2
    end

    it 'matches addresses that match on address attributes' do
      a1 = build(:address, master_address_id: 1, street: '1  way',
                           city: 'Some Where', state: 'MA', country: 'USA',
                           postal_code: '02472')
      a2 = build(:address, master_address_id: 2, street: '1 Way',
                           city: 'somewhere', state: 'ma', country: 'united states',
                           postal_code: '02472-3061')

      expect(a1).to be_equal_to a2
    end

    it 'matches if one country is blank and other fields match' do
      a1 = build(:address, master_address_id: 1, street: '1 way',
                           city: 'Somewhere ', state: 'MA  ', country: '',
                           postal_code: '02 472')
      a2 = build(:address, master_address_id: 2, street: '1 Way',
                           city: 'somewhere', state: 'ma', country: 'Canada',
                           postal_code: '02472-3061')

      expect(a1).to be_equal_to a2
    end

    it 'does not match if address fields differ' do
      a1 = build(:address, master_address_id: 1, street: '2 way',
                           city: 'Nowhere', state: 'IL', country: 'USA',
                           postal_code: '60201')
      a2 = build(:address, master_address_id: 2, street: '1 Way',
                           city: 'somewhere', state: 'ma', country: 'Canada',
                           postal_code: '02472-3061')

      expect(a1).to_not be_equal_to a2
    end

    it 'matches addresses that differ by old data server encoding' do
      street = '16C Boulevard de la Liberté'
      city = 'Cité'
      state = 'état'
      country = 'Rhône-Alpes'
      postal_code = '35220'
      a1 = build(:address, master_address_id: 1, street: street,
                           city: city, state: state, country: country,
                           postal_code: postal_code)
      a2 = build(:address, master_address_id: 2, street: old_encoding(street),
                           city: old_encoding(city), state: old_encoding(state),
                           country: old_encoding(country),
                           postal_code: old_encoding(postal_code))

      expect(a1).to be_equal_to a2
    end
  end

  context '#fix_encoding_if_equal' do
    it 'leaves a correctly encoding address alone' do
      a1 = build(:address, street: '1 Liberté')
      a2 = build(:address, street: old_encoding('1 Liberté'))

      a1.fix_encoding_if_equal(a2)

      expect(a1.street).to eq '1 Liberté'
    end

    it 'updates fields to match correctly encoded address if equal' do
      a1 = create(:address, street: old_encoding('1 Liberté'))
      a2 = create(:address, street: '1 Liberté')

      a1.fix_encoding_if_equal(a2)

      expect(a1.street).to eq '1 Liberté'
    end

    it 'leaves address alone if other is not equal' do
      a1 = build(:address, street: '1 Way')
      a2 = build(:address, street: '2 Way')

      a1.fix_encoding_if_equal(a2)

      expect(a1.street).to eq '1 Way'
    end
  end

  describe 'permitted attributes' do
    it 'defines permitted attributes' do
      expect(Address::PERMITTED_ATTRIBUTES).to be_present
    end
  end

  # Old way that DataServer used to do encoding that mangled special characters.
  def old_encoding(str)
    str.unpack('C*').pack('U*')
  end
end
