require 'spec_helper'

RSpec.describe Contact::Filter::Newsletter do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, send_newsletter: 'Email') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, send_newsletter: 'Physical') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, send_newsletter: 'Both') }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, send_newsletter: nil) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: false,
                                                                name: :newsletter,
                                                                options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                                                                          { name: 'None Selected', id: 'none' },
                                                                          { name: 'All', id: 'all' },
                                                                          { name: 'Physical', id: 'address' },
                                                                          { name: 'Email', id: 'email' },
                                                                          { name: 'Both', id: 'both' }],
                                                                parent: nil,
                                                                title: 'Newsletter Recipients',
                                                                type: 'radio',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { newsletter: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { newsletter: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { newsletter: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by newsletter none' do
      it 'returns only contacts that have no newsletter option selected' do
        expect(described_class.query(contacts, { newsletter: 'none' }, nil).to_a).to eq [contact_four]
      end
    end

    context 'filter by newsletter all' do
      it 'returns all contacts that have any newsletter option selected, but not blank' do
        expect(described_class.query(contacts, { newsletter: 'all' }, nil).to_a).to eq [contact_one, contact_two, contact_three]
      end
    end

    context 'filter by newsletter physical' do
      it 'returns all contacts that have physical or both newsletter options selected' do
        expect(described_class.query(contacts, { newsletter: 'address' }, nil).to_a).to eq [contact_two, contact_three]
      end
    end

    context 'filter by newsletter email' do
      it 'returns all contacts that have email or both newsletter options selected' do
        expect(described_class.query(contacts, { newsletter: 'email' }, nil).to_a).to eq [contact_one, contact_three]
      end
    end

    context 'filter by newsletter both' do
      it 'returns all contacts that have the both newsletter option selected' do
        expect(described_class.query(contacts, { newsletter: 'both' }, nil).to_a).to eq [contact_three]
      end
    end
  end
end