RSpec.describe Task::Filter::ExcludeTags do
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
        expect(described_class.query(tasks, { exclude_tags: {} }, nil)).to eq nil
        expect(described_class.query(tasks, { exclude_tags: [] }, nil)).to eq nil
        expect(described_class.query(tasks, { exclude_tags: '' }, nil)).to eq nil
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
  end
end
