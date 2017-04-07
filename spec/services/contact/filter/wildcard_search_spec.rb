require 'rails_helper'

RSpec.describe Contact::Filter::WildcardSearch do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:person) { create(:person, email_addresses: [build(:email_address, email: 'email@gmail.com')], phone_numbers: [build(:phone_number, number: '514 122-4362')]) }
  let!(:contact_one) { create(:contact, account_list: account_list, notes: 'random notes', name: 'A name', donor_accounts: [build(:donor_account, account_number: '1234')]) }
  let!(:contact_two) { create(:contact, account_list: account_list, notes: 'notes present') }
  let!(:contact_three) { create(:contact, account_list: account_list, notes: 'missing present', people: [person]) }

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
      it 'returns only tasks that are within the updated_at range' do
        expect(described_class.query(contacts, { wildcard_search: 'name' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { wildcard_search: "#{person.last_name}, #{person.first_name}" }, nil).to_a).to match_array [contact_three]
        expect(described_class.query(contacts, { wildcard_search: 'notes' }, nil).to_a).to match_array [contact_one, contact_two]
        expect(described_class.query(contacts, { wildcard_search: '122' }, nil).to_a).to match_array [contact_three]
        expect(described_class.query(contacts, { wildcard_search: 'email' }, nil).to_a).to match_array [contact_three]
      end
    end
  end
end
