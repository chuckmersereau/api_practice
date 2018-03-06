require 'rails_helper'

RSpec.describe Contact::Filter::PledgeCurrency do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, pledge_currency: 'CAD') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, pledge_currency: 'GBP') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, pledge_currency: 'USD') }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, pledge_currency: 'USD') }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(name: :pledge_currency,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                          { name: 'CAD', id: 'CAD' },
                                                                          { name: 'GBP', id: 'GBP' },
                                                                          { name: 'USD', id: 'USD' }],
                                                                parent: 'Commitment Details',
                                                                title: 'Commitment Currency',
                                                                type: 'multiselect')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { locale: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { locale: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { locale: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by address historic' do
      it 'returns only contacts that have the locale' do
        expect(described_class.query(contacts, { pledge_currency: 'USD' }, [account_list]).to_a).to match_array [contact_three, contact_four]
        expect(described_class.query(contacts, { pledge_currency: 'CAD' }, [account_list]).to_a).to eq [contact_one]
      end
    end
  end
end
