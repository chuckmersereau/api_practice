require 'rails_helper'

RSpec.describe Contact::Filter::Notes do
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
    create(:contact, account_list: account_list, notes: 'missing notes', name: 'Jones, Zhong', people: [person])
  end
  let!(:contact_four) { create(:contact, account_list: account_list, notes: nil, name: 'Bob, Bindal') }

  def wildcard_search_notes(value, note_search)
    described_class.query(contacts, { wildcard_search: value, notes: { wildcard_note_search: note_search } }, nil).to_a
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

    context 'filter notes with wildcard search' do
      it 'returns only contacts that match the search query' do
        expect(wildcard_search_notes('Jones', 'notes')).to match_array [contact_one, contact_three]
        expect(wildcard_search_notes('Jones', 'missing notes')).to eq [contact_three]
        expect(wildcard_search_notes('Freddie', 'random notes')).to eq [contact_one]
      end
    end
  end
end
