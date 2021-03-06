require 'rails_helper'

RSpec.describe Contact::Filter::PledgeAmount do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, pledge_amount: 100.00) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, pledge_amount: 100.00) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, pledge_amount: 1.00) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, pledge_amount: nil) }

  describe '#config' do
    it 'returns expected config' do
      options = [{ name: '-- Any --', id: '', placeholder: 'None' },
                 { name: 1.0, id: 1.0 },
                 { name: 100.0, id: 100.0 }]
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :pledge_amount,
                                                                options: options,
                                                                parent: 'Commitment Details',
                                                                title: 'Commitment Amount',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge_amount: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge_amount: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge_amount: { wut: '???', hey: 'yo' } }, nil)).to eq(nil)
      end
    end

    context 'filter by amounts' do
      it 'returns only contacts with a pledge amount in the filters' do
        result = described_class.query(contacts, { pledge_amount: '100.0' }, nil).to_a
        expect(result).to match_array [contact_one, contact_two]

        result = described_class.query(contacts, { pledge_amount: '1' }, nil).to_a
        expect(result).to eq [contact_three]

        result = described_class.query(contacts, { pledge_amount: '100.0, 1.0, 200.0' }, nil).to_a
        expect(result).to match_array [contact_one, contact_two, contact_three]
      end
    end
  end
end
