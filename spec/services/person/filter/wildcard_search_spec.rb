require 'rails_helper'

RSpec.describe Person::Filter::WildcardSearch do
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let!(:person_one) do
    create(:person, email_addresses: [build(:email_address, email: 'email@gmail.com')],
                    phone_numbers: [build(:phone_number, number: '514 122-4362')])
  end
  let!(:person_two) { create(:person, first_name: 'Freddie', last_name: 'Jones') }
  let!(:person_three) { create(:person, first_name: 'Donald', last_name: 'Duck') }
  let!(:person_four) { create(:person) }

  describe '#config' do
    it 'does not have config' do
      expect(described_class.config([account_list])).to eq(nil)
    end
  end

  describe '#query' do
    let(:people) { Person.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(people, {}, nil)).to eq(nil)
        expect(described_class.query(people, { wildcard_search: {} }, nil)).to eq nil
        expect(described_class.query(people, { wildcard_search: [] }, nil)).to eq nil
        expect(described_class.query(people, { wildcard_search: '' }, nil)).to eq nil
      end
    end

    context 'filter with wildcard search' do
      it 'returns only contacts that match the search query' do
        expect(described_class.query(people, { wildcard_search: 'Freddie' }, nil).to_a).to match_array [person_two]
        expect(described_class.query(people, { wildcard_search: 'Duck' }, nil).to_a).to match_array [person_three]
        expect(described_class.query(people, { wildcard_search: '122' }, nil).to_a).to match_array [person_one]
        expect(described_class.query(people, { wildcard_search: 'email' }, nil).to_a).to match_array [person_one]
      end

      it 'searches person first and last name regardless of order, case, or commas' do
        expect(described_class.query(people, { wildcard_search: 'freddie JONES,' }, nil).to_a).to match_array [person_two]
        expect(described_class.query(people, { wildcard_search: 'jones, freddie' }, nil).to_a).to match_array [person_two]
      end
    end
  end
end
