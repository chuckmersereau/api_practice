require 'rails_helper'

RSpec.describe Contact::Filter::Likely do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, likely_to_give: 'Least Likely') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, likely_to_give: 'Likely') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, likely_to_give: 'Most Likely') }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, likely_to_give: nil) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :likely,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                          { name: '-- None --', id: 'none' },
                                                                          { name: 'Least Likely', id: 'Least Likely' },
                                                                          { name: 'Likely', id: 'Likely' },
                                                                          { name: 'Most Likely', id: 'Most Likely' }],
                                                                parent: 'Contact Details',
                                                                title: 'Likely To Give',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { referrer: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { referrer: [] }, nil)).to eq(nil)
      end
    end

    context 'filter by no likely to give' do
      it 'returns only contacts that have no likely to give' do
        expect(described_class.query(contacts, { likely: 'none' }, nil).to_a).to eq [contact_four]
      end
    end

    context 'filter by likely to give' do
      it 'filters multiple likely to give' do
        expect(described_class.query(contacts, { likely: 'Least Likely, Likely' }, nil).to_a).to match_array [contact_one, contact_two]
      end
      it 'filters a single likely to give' do
        expect(described_class.query(contacts, { likely: 'Most Likely' }, nil).to_a).to eq [contact_three]
      end
    end

    context 'multiple filters' do
      it 'returns contacts matching multiple filters' do
        expect(described_class.query(contacts, { likely: 'none, Most Likely, Likely' }, nil).to_a).to match_array [contact_two, contact_three, contact_four]
      end
    end
  end
end
