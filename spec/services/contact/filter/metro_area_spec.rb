require 'rails_helper'

RSpec.describe Contact::Filter::MetroArea do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }
  let!(:contact_five)  { create(:contact, account_list_id: account_list.id) }

  let!(:address_one)   { create(:address, metro_area: 'My Metro') }
  let!(:address_two)   { create(:address, metro_area: 'My Metro') }
  let!(:address_three) { create(:address, metro_area: nil) }
  let!(:address_four)  { create(:address, metro_area: nil) }
  let!(:address_five)  { create(:address, metro_area: 'My Metro', historic: true) }

  before do
    contact_one.addresses << address_one
    contact_two.addresses << address_two
    contact_three.addresses << address_three
    contact_four.addresses << address_four
    contact_five.addresses << address_five
  end

  describe '#config' do
    it 'returns expected config' do
      options = [{ name: '-- Any --', id: '', placeholder: 'None' },
                 { name: '-- None --', id: 'none' },
                 { name: 'My Metro', id: 'My Metro' }]
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :metro_area,
                                                                options: options,
                                                                parent: 'Contact Location',
                                                                title: 'Metro Area',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { metro_area: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { metro_area: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { metro_area: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by no metro_area' do
      it 'returns only contacts that have no metro_area' do
        result = described_class.query(contacts, { metro_area: 'none' }, nil).to_a

        expect(result).to match_array [contact_three, contact_four]
      end
    end

    context 'filter by metro_area' do
      it 'filters multiple metro_areas' do
        result = described_class.query(contacts, { metro_area: 'My Metro, My Metro' }, nil).to_a

        expect(result).to match_array [contact_one, contact_two]
      end
      it 'filters a single metro_area' do
        result = described_class.query(contacts, { metro_area: 'My Metro' }, nil).to_a

        expect(result).to match_array [contact_one, contact_two]
      end
    end

    context 'multiple filters' do
      it 'returns contacts matching multiple filters' do
        result = described_class.query(contacts, { metro_area: 'My Metro, none' }, nil).to_a

        expect(result).to match_array [contact_one, contact_two, contact_three, contact_four]
      end
    end

    context 'address historic' do
      it 'returns contacts matching the metro_area with historic addresses' do
        result = described_class.query(contacts, { metro_area: 'My Metro', address_historic: 'true' }, nil).to_a

        expect(result).to eq [contact_five]
      end
    end
  end
end
