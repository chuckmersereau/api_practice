require 'rails_helper'

RSpec.describe Person::Filter::Deceased do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }

  let!(:person_one)   { create(:person, contacts: [contact_one], deceased: true) }
  let!(:person_two)   { create(:person, contacts: [contact_two], deceased: true) }
  let!(:person_three) { create(:person, contacts: [contact_one], deceased: false) }
  let!(:person_four)  { create(:person, contacts: [contact_two], deceased: false) }

  describe '#query' do
    let(:scope) { account_list.people }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(scope, {}, nil)).to eq(nil)
        expect(described_class.query(scope, { deceased: {} }, nil)).to eq(nil)
        expect(described_class.query(scope, { deceased: [] }, nil)).to eq(nil)
        expect(described_class.query(scope, { deceased: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by deceased' do
      it 'returns only people that have deceased' do
        expect(described_class.query(scope, { deceased: 'true' }, nil).to_a).to match_array [person_one, person_two]
      end
    end

    context 'filter by not deceased' do
      it 'returns only people that have not deceased' do
        expect(described_class.query(scope, { deceased: 'false' }, nil).to_a).to match_array [person_three, person_four]
      end
    end
  end
end
