require 'rails_helper'
require_relative '../../../../app/services/contact/filter/base'
require_relative '../../../../app/services/person/filter/wildcard_search'
require_relative '../../../../app/services/person/filter/base'

RSpec.describe Contact::Filter::WildcardSearch do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:person) do
    create(:person, first_name: 'PersonFirstName', last_name: 'PersonLastName',
                    email_addresses: [build(:email_address, email: 'email@gmail.com')],
                    phone_numbers: [build(:phone_number, number: '514 122-4362')])
  end
  let!(:contact_one) do
    create(:contact, account_list: account_list,
                     notes: 'the random notes',
                     name: 'Jones, Freddie',
                     donor_accounts: [build(:donor_account, account_number: '1234567890')])
  end
  let!(:contact_two) do
    create(:contact, account_list: account_list, notes: 'this is my favourite person', name: 'Dolly, Doe')
  end
  let!(:contact_three) do
    create(:contact, account_list: account_list, notes: 'missing', name: 'Jill, Zhong', people: [person])
  end
  let!(:contact_four) { create(:contact, account_list: account_list, notes: nil, name: 'Bob, Bindal') }

  describe '#config' do
    it 'does not have config' do
      expect(described_class.config([account_list])).to eq(nil)
    end
  end

  def wildcard_search(value)
    described_class.query(contacts, { wildcard_search: value }, nil).to_a
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
        expect(wildcard_search('Freddie')).to eq [contact_one]
        expect(wildcard_search('1234567890')).to eq [contact_one]
        expect(wildcard_search(person.last_name)).to eq [contact_three]
        expect(wildcard_search('122')).to eq [contact_three]
        expect(wildcard_search('random notes')).to eq [contact_one]
        expect(wildcard_search('email')).to eq [contact_three]
      end

      it 'searches contact name regardless of order, case, or commas' do
        expect(wildcard_search('freddie JONES,')).to eq [contact_one]
        expect(wildcard_search('jones, freddie')).to eq [contact_one]
      end

      it 'searches person first and last name regardless of order, case, or commas' do
        expect(wildcard_search('Personfirstname, personlastName')).to eq [contact_three]
        expect(wildcard_search(',PERSONLASTNAME personfirstname')).to eq [contact_three]
      end

      it 'searches names with more than two words' do
        contact_one.update(name: 'Min jun, Park')
        contact_two.update(name: 'Seo-yun, Kim')
        expect(wildcard_search('park min jun')).to eq [contact_one]
        expect(wildcard_search('park min-jun')).to eq [contact_one]
        expect(wildcard_search('seo yun kim')).to eq [contact_two]
        expect(wildcard_search('kim seo-yun')).to eq [contact_two]
      end
    end
  end
end
