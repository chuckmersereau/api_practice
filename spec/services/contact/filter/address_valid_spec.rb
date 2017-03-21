require 'rails_helper'

RSpec.describe Contact::Filter::AddressValid do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

  let!(:address_one)   { create(:address, addressable: contact_one,   primary_mailing_address: false) }
  let!(:address_two)   { create(:address, addressable: contact_two,   primary_mailing_address: false) }
  let!(:address_three) { create(:address, addressable: contact_three, primary_mailing_address: false) }
  let!(:address_four)  { create(:address, addressable: contact_four,  primary_mailing_address: false) }

  let!(:primary_address_one)   { create(:address, addressable: contact_one, primary_mailing_address: true) }
  let!(:primary_address_two)   { create(:address, addressable: contact_one, primary_mailing_address: true) }
  let!(:primary_address_three) { create(:address, addressable: contact_two, primary_mailing_address: true) }

  before do
    address_one.update(valid_values: true)
    address_two.update(valid_values: true)
    address_three.update(valid_values: true)
    address_four.update(valid_values: false)
    primary_address_one.update(valid_values: true)
    primary_address_two.update(valid_values: true)
    primary_address_three.update(valid_values: true)
  end

  describe '#config' do
    it 'does not support returning config' do
      expect(described_class.config([account_list])).to eq nil
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { address_valid: {} },    nil).to_a).to eq([])
        expect(described_class.query(contacts, { address_valid: [] },    nil).to_a).to eq([])
        expect(described_class.query(contacts, { address_valid: '' },    nil).to_a).to eq([])
        expect(described_class.query(contacts, { address_valid: 'wut' }, nil).to_a).to eq(contacts)
      end
    end

    context 'filter by not address valid' do
      it 'returns only contacts that have an invalid address' do
        expect(described_class.query(contacts, { address_valid: 'false' }, nil).to_a).to match_array [contact_four, contact_one]
      end
    end
  end
end
