require 'rails_helper'

RSpec.describe Contact::Filter::StatusValid do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, status_valid: false) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, status_valid: true) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, status_valid: true) }

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
        expect(described_class.query(contacts, { status_valid: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { status_valid: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { status_valid: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by status_valid' do
      it 'returns only contacts that have a status_valid set to true' do
        expect(described_class.query(contacts, { status_valid: 'true' }, nil).to_a).to match_array [contact_three, contact_four]
      end
    end

    context 'filter by not status_valid' do
      it 'returns only contacts that have a status_valid set to false' do
        expect(described_class.query(contacts, { status_valid: 'false' }, nil).to_a).to match_array [contact_two]
      end
    end
  end
end
