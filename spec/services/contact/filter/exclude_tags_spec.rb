require 'rails_helper'

RSpec.describe Contact::Filter::ExcludeTags do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, tag_list: 'tag1,tag2') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, tag_list: 'tag1') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, tag_list: 'tag3') }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, tag_list: '') }

  describe '#config' do
    it 'does not have config' do
      expect(described_class.config([account_list])).to eq(nil)
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { exclude_tags: {} }, nil)).to eq nil
        expect(described_class.query(contacts, { exclude_tags: [] }, nil)).to eq nil
        expect(described_class.query(contacts, { exclude_tags: '' }, nil)).to eq nil
      end
    end

    context 'filter exclude tags' do
      it 'returns only contacts that do not have the tag' do
        expect(described_class.query(contacts, { exclude_tags: 'tag1' }, nil).to_a).to match_array [contact_three, contact_four]
      end
      it 'returns only contacts that do not have multiple tags' do
        expect(described_class.query(contacts, { exclude_tags: 'tag1,tag2,tag3' }, nil).to_a).to match_array [contact_four]
      end
      it 'accepts tags as comma separated string' do
        expect(described_class.query(contacts, { exclude_tags: 'tag1,tag2,tag3' }, nil).to_a).to match_array [contact_four]
      end

      context 'with a backslash' do
        before { contact_four.update!(tag_list: 'foo\bar') }

        it 'does not fail with tags that include backslashes' do
          expected_array = [contact_one, contact_two, contact_three]

          expect(described_class.query(contacts, { exclude_tags: 'foo\bar' }, nil).to_a).to match_array expected_array
        end
      end
    end
  end
end
