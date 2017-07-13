require 'rails_helper'

RSpec.describe Contact::Filter::Locale do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, locale: 'fr-CA') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, locale: 'fr-FR') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, locale: 'en-US') }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, locale: 'en-US') }

  describe '#config' do
    it 'returns expected config' do
      expected_config = {
        name: :locale,
        multiple: true,
        default_selection: '',
        options: [
          { name: '-- Any --', id: '', placeholder: 'None' },
          { name: '-- Unspecified --', id: 'null' },
          { name: 'en-US', id: 'en-US' },
          { name: 'fr-CA', id: 'fr-CA' },
          { name: 'fr-FR', id: 'fr-FR' }],
        parent: 'Contact Details',
        priority: 26,
        title: 'Language',
        type: 'multiselect'
      }

      expect(described_class.config([account_list])).to match(expected_config)
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { locale: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { locale: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { locale: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by address historic' do
      it 'returns only contacts that have the locale' do
        expect(described_class.query(contacts, { locale: 'en-US' }, nil).to_a).to match_array [contact_three, contact_four]
        expect(described_class.query(contacts, { locale: 'fr-CA' }, nil).to_a).to match_array [contact_one]
      end
    end
  end
end
