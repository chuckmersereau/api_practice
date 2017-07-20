require 'rails_helper'

RSpec.describe Contact::Filter::Church do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, church_name: 'My Church') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, church_name: 'First Pedestrian Church') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, church_name: nil) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, church_name: nil) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :church,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                          { name: '-- None --', id: 'none' },
                                                                          { name: 'First Pedestrian Church', id: 'First Pedestrian Church' },
                                                                          { name: 'My Church', id: 'My Church' }],
                                                                parent: 'Contact Details',
                                                                title: 'Church',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { church: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { church: [] }, nil)).to eq(nil)
      end
    end

    context 'filter by no church' do
      it 'returns only contacts that have no church' do
        expect(described_class.query(contacts, { church: 'none' }, nil).to_a).to match_array [contact_three, contact_four]
      end
    end

    context 'filter by church' do
      it 'filters multiple churches' do
        expect(described_class.query(contacts, { church: 'My Church, First Pedestrian Church' }, nil).to_a).to match_array [contact_one, contact_two]
      end
      it 'filters a single churche' do
        expect(described_class.query(contacts, { church: 'My Church' }, nil).to_a).to eq [contact_one]
      end
    end

    context 'multiple filters' do
      it 'returns contacts matching multiple filters' do
        expect(described_class.query(contacts, { church: 'My Church, none' }, nil).to_a).to match_array [contact_one, contact_three, contact_four]
      end
    end
  end
end
