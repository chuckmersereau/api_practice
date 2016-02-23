require 'spec_helper'

describe AddressMethods do
  let(:contact) { create(:contact) }
  let(:donor_account) { create(:donor_account) }

  context '#merge_addresses' do
    def expect_merge_addresses_works(addressable)
      address1 = create(:address, street: '1 Way', master_address_id: 1)
      address2 = create(:address, street: '1 Way', master_address_id: 1)
      address3 = create(:address, street: '2 Way', master_address_id: 2)
      addressable.addresses << address1
      addressable.addresses << address2
      addressable.addresses << address3

      expect do
        addressable.merge_addresses
      end.to change(Address, :count).from(3).to(2)

      expect(Address.find_by_id(address1.id)).to be_nil
      expect(Address.find_by_id(address2.id)).to eq(address2)
      expect(Address.find_by_id(address3.id)).to eq(address3)
    end

    it 'works for contact' do
      expect_merge_addresses_works(contact)
    end

    it 'works for donor_account' do
      expect_merge_addresses_works(donor_account)
    end
  end

  context '#blank_or_duplicate_address?' do
    it 'returns false if an id specified' do
      expect(contact.blank_or_duplicate_address?('id' => '1')).to be false
    end

    it 'returns true if address fields blank' do
      expect(contact.blank_or_duplicate_address?({})).to be true
    end

    it 'returns false if any address field is specified' do
      ['street', 'city', 'state', 'country', 'postal_code', :street, :city, :state, :country, :postal_code].each do |field|
        expect(contact.blank_or_duplicate_address?(field => 'a')).to be false
      end
    end

    it 'returns true for a duplicate address by by matching attributes, false if not matching' do
      a = create(:address)
      contact.addresses << a
      expect(contact.blank_or_duplicate_address?(street: a.street, city: a.city, country: a.country,
                                                 postal_code: a.postal_code)).to be true
      expect(contact.blank_or_duplicate_address?(street: 'other street')).to be false
    end

    it 'returns true for a duplicate address by by matching attributes if country set alternate name' do
      a = create(:address, country: 'USA')
      contact.addresses << a
      expect(contact.blank_or_duplicate_address?(street: a.street, city: a.city, country: 'USA',
                                                 postal_code: a.postal_code)).to be true
    end
  end

  context '#primary_address' do

  end
end
