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

      expect(Address.find_by(id: address1.id)).to be_nil
      expect(Address.find_by(id: address2.id)).to eq(address2)
      expect(Address.find_by(id: address3.id)).to eq(address3)
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
    it 'gives a consistent non-deleted, non-historic primary address' do
      contact = create(:contact)
      addr1 = create(:address, street: '1', primary_mailing_address: true, deleted: true)
      addr2 = create(:address, street: '2', primary_mailing_address: true, historic: true)
      addr3 = create(:address, street: '3', primary_mailing_address: false)
      addr4 = create(:address, street: '4', primary_mailing_address: true, city: 'b')
      addr5 = create(:address, street: '5', primary_mailing_address: true, city: 'a')
      contact.addresses << [addr1, addr2, addr3, addr4, addr5]

      # Check that we get the same address even if db record order changes
      Address.connection.execute('CLUSTER addresses USING index_addresses_on_lower_city')
      expect(contact.primary_address).to eq addr4
      Address.connection.execute('CLUSTER addresses USING addresses_pkey')
      expect(contact.primary_address).to eq addr4
    end
  end

  context '#addresses' do
    it 'gives a consistent first if none are primary and record order changes' do
      contact = create(:contact)
      addr1 = create(:address, street: '1', primary_mailing_address: false,
                               city: 'b', addressable: contact)
      create(:address, street: '2', primary_mailing_address: false, city: 'a',
                       addressable: contact)

      # Check that we get the same address even if db record order changes
      Address.connection.execute('CLUSTER addresses USING index_addresses_on_lower_city')
      expect(contact.addresses.first).to eq addr1
      Address.connection.execute('CLUSTER addresses USING addresses_pkey')
      expect(contact.addresses.first).to eq addr1
    end
  end

  context '#copy_address' do
    it 'moves over the main address attributes and sets source info' do
      donor_account = create(:donor_account)
      donor_address = create(:address, street: '1 Rd')
      donor_account.addresses << donor_address
      contact = create(:contact)

      contact.copy_address(address: donor_address, source: 'DataServer', source_donor_account_id: 1)

      expect(contact.addresses.size).to eq 1
      contact_address = contact.addresses.first
      expect(contact_address).to_not eq donor_address
      expect(contact.addresses.first.street).to eq '1 Rd'
    end
  end
end
