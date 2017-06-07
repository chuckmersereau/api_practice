require 'rails_helper'
require_relative '../../../../app/services/contact/filter/base'
require_relative '../../../../app/services/person/filter/wildcard_search'
require_relative '../../../../app/services/person/filter/base'

RSpec.describe Contact::Filter::WildcardSearch do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:person) do
    create(:person, first_name: 'PersonFirstName', last_name: 'PersonLastName',
                    email_addresses: [build(:email_address, email: 'email@gmail.com')],
                    phone_numbers: [build(:phone_number, number: '514 122-4362')])
  end
  let!(:contact_one) { create(:contact, account_list: account_list, notes: 'the random notes', name: 'Jones, Freddie', donor_accounts: [build(:donor_account, account_number: '1234567890')]) }
  let!(:contact_two) { create(:contact, account_list: account_list, notes: 'this is my favourite person', name: 'Dolly, Doe') }
  let!(:contact_three) { create(:contact, account_list: account_list, notes: 'missing', name: 'Jill, Zhong', people: [person]) }
  let!(:contact_four) { create(:contact, account_list: account_list, notes: nil, name: 'Bob, Bindal') }

  describe '#config' do
    it 'does not have config' do
      expect(described_class.config([account_list])).to eq(nil)
    end
  end

  describe '#query' do
    let(:contacts) { account_list.contacts }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { wildcard_search: {} }, nil)).to eq nil
        expect(described_class.query(contacts, { wildcard_search: [] }, nil)).to eq nil
        expect(described_class.query(contacts, { wildcard_search: '' }, nil)).to eq nil
      end
    end

    context 'filter with wildcard search' do
      it 'returns only contacts that match the search query' do
        expect(described_class.query(contacts, { wildcard_search: 'Freddie' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: '1234567890' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: person.last_name }, nil).to_a).to match_array [contact_three]
        expect(described_class.query(contacts, { wildcard_search: '122' }, nil).to_a).to match_array [contact_three]
        expect(described_class.query(contacts, { wildcard_search: 'random notes' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: 'email' }, nil).to_a).to match_array [contact_three]
      end

      it 'searches contact name regardless of order, case, or commas' do
        expect(described_class.query(contacts, { wildcard_search: 'freddie JONES,' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: 'jones, freddie' }, nil).to_a).to match_array [contact_one]
      end

      it 'searches person first and last name regardless of order, case, or commas' do
        expect(described_class.query(contacts, { wildcard_search: 'Personfirstname, personlastName' }, nil).to_a).to match_array [contact_three]
        expect(described_class.query(contacts, { wildcard_search: ',PERSONLASTNAME personfirstname' }, nil).to_a).to match_array [contact_three]
      end

      it 'searches names with more than two words' do
        contact_one.update(name: 'Min jun, Park')
        contact_two.update(name: 'Seo-yun, Kim')
        expect(described_class.query(contacts, { wildcard_search: 'park min jun' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: 'park min-jun' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: 'seo yun kim' }, nil).to_a).to match_array [contact_two]
        expect(described_class.query(contacts, { wildcard_search: 'kim seo-yun' }, nil).to_a).to match_array [contact_two]
      end
    end
  end
end
