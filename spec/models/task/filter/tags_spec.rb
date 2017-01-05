require 'spec_helper'

RSpec.describe Task::Filter::Tags do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list_id: account_list.id, tag_list: 'tag1,tag2') }
  let!(:task_two)   { create(:task, account_list_id: account_list.id, tag_list: 'tag1') }
  let!(:task_three) { create(:task, account_list_id: account_list.id, tag_list: 'tag3') }
  let!(:task_four)  { create(:task, account_list_id: account_list.id, tag_list: '') }

  describe '#config' do
    it 'does not have config' do
      expect(described_class.config([account_list])).to eq(nil)
    end
  end

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { tags: {} }, nil)).to eq nil
        expect(described_class.query(tasks, { tags: [] }, nil)).to eq nil
        expect(described_class.query(tasks, { tags: '' }, nil)).to eq nil
        expect(described_class.query(tasks, { exclude_tags: {} }, nil)).to eq nil
        expect(described_class.query(tasks, { exclude_tags: [] }, nil)).to eq nil
        expect(described_class.query(tasks, { exclude_tags: '' }, nil)).to eq nil
      end
    end

    context 'filter with tags' do
      it 'returns only tasks that have the tag' do
        expect(described_class.query(tasks, { tags: 'tag1' }, nil).to_a).to match_array [task_one, task_two]
      end
      it 'returns only tasks that have multiple tags' do
        expect(described_class.query(tasks, { tags: 'tag1,tag2' }, nil).to_a).to match_array [task_one]
      end
      it 'accepts tags as comma separated string' do
        expect(described_class.query(tasks, { tags: 'tag1,tag2' }, nil).to_a).to match_array [task_one]
      end
      it 'accepts tags as an array' do
        expect(described_class.query(tasks, { tags: %w(tag1 tag2) }, nil).to_a).to match_array [task_one]
      end
    end

    context 'filter exclude tags' do
      it 'returns only tasks that do not have the tag' do
        expect(described_class.query(tasks, { exclude_tags: 'tag1' }, nil).to_a).to match_array [task_three, task_four]
      end
      it 'returns only tasks that do not have multiple tags' do
        expect(described_class.query(tasks, { exclude_tags: 'tag1,tag2,tag3' }, nil).to_a).to match_array [task_four]
      end
      it 'accepts tags as comma separated string' do
        expect(described_class.query(tasks, { exclude_tags: 'tag1,tag2,tag3' }, nil).to_a).to match_array [task_four]
      end
      it 'accepts tags as an array' do
        expect(described_class.query(tasks, { exclude_tags: %w(tag1 tag2 tag3) }, nil).to_a).to match_array [task_four]
      end
    end

    context 'filter with and exclude tags' do
      it 'returns only tasks that do not have a tag but also have a tag' do
        expect(described_class.query(tasks, { exclude_tags: ['tag1'], tags: ['tag2'] }, nil).to_a).to match_array []
        expect(described_class.query(tasks, { exclude_tags: ['tag2'], tags: ['tag1'] }, nil).to_a).to match_array [task_two]
      end
    end
  end
end
