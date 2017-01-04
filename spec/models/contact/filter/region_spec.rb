require 'spec_helper'

RSpec.describe Contact::Filter::Region do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }
  let!(:contact_five)  { create(:contact, account_list_id: account_list.id) }

  let!(:address_one)   { create(:address, region: 'My Region') }
  let!(:address_two)   { create(:address, region: 'My Region') }
  let!(:address_three) { create(:address, region: nil) }
  let!(:address_four)  { create(:address, region: nil) }
  let!(:address_five)  { create(:address, region: 'My Region', historic: true) }

  before do
    contact_one.addresses << address_one
    contact_two.addresses << address_two
    contact_three.addresses << address_three
    contact_four.addresses << address_four
    contact_five.addresses << address_five
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :region,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                          { name: '-- None --', id: 'none' },
                                                                          { name: 'My Region', id: 'My Region' }],
                                                                parent: 'Contact Location',
                                                                title: 'Region',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { region: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { region: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { region: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by no region' do
      it 'returns only contacts that have no region' do
        expect(described_class.query(contacts, { region: ['none'] }, nil).to_a).to match_array [contact_three, contact_four]
      end
    end

    context 'filter by region' do
      it 'filters multiple regions' do
        expect(described_class.query(contacts, { region: ['My Region', 'My Region'] }, nil).to_a).to match_array [contact_one, contact_two]
      end
      it 'filters a single region' do
        expect(described_class.query(contacts, { region: 'My Region' }, nil).to_a).to match_array [contact_one, contact_two]
      end
    end

    context 'multiple filters' do
      it 'returns contacts matching multiple filters' do
        expect(described_class.query(contacts, { region: ['My Region', 'none'] }, nil).to_a).to match_array [contact_one, contact_two, contact_three, contact_four]
      end
    end

    context 'address historic' do
      it 'returns contacts matching the region with historic addresses' do
        expect(described_class.query(contacts, { region: 'My Region', address_historic: 'true' }, nil).to_a).to eq [contact_five]
      end
    end
  end
end
