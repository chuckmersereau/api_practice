require 'spec_helper'

RSpec.describe Contact::Filter::Tags do
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
        expect(described_class.query(contacts, { tags: {} }, nil)).to eq nil
        expect(described_class.query(contacts, { tags: [] }, nil)).to eq nil
        expect(described_class.query(contacts, { tags: '' }, nil)).to eq nil
        expect(described_class.query(contacts, { exclude_tags: {} }, nil)).to eq nil
        expect(described_class.query(contacts, { exclude_tags: [] }, nil)).to eq nil
        expect(described_class.query(contacts, { exclude_tags: '' }, nil)).to eq nil
      end
    end

    context 'filter with tags' do
      it 'returns only contacts that have the tag' do
        expect(described_class.query(contacts, { tags: 'tag1' }, nil).to_a).to match_array [contact_one, contact_two]
      end
      it 'returns only contacts that have multiple tags' do
        expect(described_class.query(contacts, { tags: 'tag1,tag2' }, nil).to_a).to match_array [contact_one]
      end
      it 'accepts tags as comma separated string' do
        expect(described_class.query(contacts, { tags: 'tag1,tag2' }, nil).to_a).to match_array [contact_one]
      end
      it 'accepts tags as an array' do
        expect(described_class.query(contacts, { tags: %w(tag1 tag2) }, nil).to_a).to match_array [contact_one]
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
      it 'accepts tags as an array' do
        expect(described_class.query(contacts, { exclude_tags: %w(tag1 tag2 tag3) }, nil).to_a).to match_array [contact_four]
      end
    end

    context 'filter with and exclude tags' do
      it 'returns only contacts that do not have a tag but also have a tag' do
        expect(described_class.query(contacts, { exclude_tags: ['tag1'], tags: ['tag2'] }, nil).to_a).to match_array []
        expect(described_class.query(contacts, { exclude_tags: ['tag2'], tags: ['tag1'] }, nil).to_a).to match_array [contact_two]
      end
    end
  end
end
