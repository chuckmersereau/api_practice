require 'rails_helper'

RSpec.describe Contact::Filter::NameLike do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, name: 'First Name') }
  let!(:contact_two)   { create(:contact, name: 'Name') }
  let!(:contact_three) { create(:contact) }

  describe '#config' do
    it 'does not support returning config' do
      expect(described_class.config([account_list])).to eq nil
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { name_like: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { name_like: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { name_like: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by contact name' do
      it 'returns only contacts that start with the search query' do
        expect(described_class.query(contacts, { name_like: 'First' }, nil).to_a).to match_array [contact_one]
        expect(described_class.query(contacts, { name_like: 'Name' }, nil).to_a).to match_array [contact_two]
      end
    end
  end
end
