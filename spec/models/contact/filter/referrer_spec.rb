require 'spec_helper'

RSpec.describe Contact::Filter::Referrer do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

  before do
    ContactReferral.create! referred_by: contact_one, referred_to: contact_two
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config(account_list)).to include(multiple: true,
                                                              name: :referrer,
                                                              options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                        { name: '-- None --', id: 'none' },
                                                                        { name: '-- Has referrer --', id: 'any' },
                                                                        { name: 'Doe, John', id: contact_one.id }],
                                                              parent: nil,
                                                              title: 'Referrer',
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

    context 'filter by no referrer' do
      it 'returns only contacts that have no referrer' do
        expect(described_class.query(contacts, { referrer: ['none'] }, nil).to_a).to match_array [contact_one, contact_three, contact_four]
      end
    end

    context 'filter by any referrer' do
      it 'returns only contacts that have a referrer' do
        expect(described_class.query(contacts, { referrer: 'any' }, nil).to_a).to match_array [contact_two]
      end
    end

    context 'filter by referrer' do
      it 'filters multiple referrers' do
        expect(described_class.query(contacts, { referrer: [contact_one.id.to_s, contact_one.id.to_s] }, nil).to_a).to match_array [contact_two]
      end
      it 'filters a single referrer' do
        expect(described_class.query(contacts, { referrer: contact_one.id.to_s }, nil).to_a).to match_array [contact_two]
      end
    end

    context 'multiple filters' do
      it 'returns contacts matching multiple filters' do
        expect(described_class.query(contacts, { referrer: [contact_one.id.to_s, 'none'] }, nil).to_a).to match_array [contact_one, contact_two, contact_three, contact_four]
      end
    end
  end
end
