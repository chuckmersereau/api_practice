require 'spec_helper'

RSpec.describe Contact::Filter::AddressHistoric do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

  let!(:address_one)   { create(:address) }
  let!(:address_two)   { create(:address) }
  let!(:address_three) { create(:address, city: nil, historic: true) }
  let!(:address_four)  { create(:address, city: nil, historic: true) }

  before do
    contact_one.addresses << address_one
    contact_two.addresses << address_two
    contact_three.addresses << address_three
    contact_four.addresses << address_four
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(name: :address_historic,
                                                              parent: 'Contact Location',
                                                              title: 'Address No Longer Valid',
                                                              type: 'single_checkbox',
                                                              default_selection: false)
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { address_historic: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { address_historic: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { address_historic: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by address historic' do
      it 'returns only contacts that have a no longer valid address' do
        expect(described_class.query(contacts, { address_historic: 'true' }, nil).to_a).to match_array [contact_three, contact_four]
      end
    end

    context 'filter by not address historic' do
      it 'returns only contacts that have a valid address' do
        expect(described_class.query(contacts, { address_historic: 'false' }, nil).to_a).to match_array [contact_one, contact_two]
      end
    end
  end
end
