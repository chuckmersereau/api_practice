require 'spec_helper'

RSpec.describe Task::Filter::Wildcard do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list_id: account_list.id, subject: 'Subject1', tag_list: 'tag1,tag2') }
  let!(:task_two)   { create(:task, account_list_id: account_list.id, subject: 'subject2', tag_list: 'tag1') }
  let!(:task_three)   { create(:task, account_list_id: account_list.id, subject: 'Subject3', tag_list: 'tag3') }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'with wildcard subject' do
      it 'returns all tasks that match the subject' do
        expect(described_class.query(tasks, { wildcard: 'subject1' }, nil).to_a).to match_array [task_one]
        expect(described_class.query(tasks, { wildcard: 'subject1' }, nil).to_a).not_to match_array [task_one, task_two, task_three]
      end
    end

    context 'with a single wildcard tag' do
      it 'returns all tasks that match the tag' do
        expect(described_class.query(tasks, { wildcard: 'tag1' }, nil).to_a).to match_array [task_one, task_two]
        expect(described_class.query(tasks, { wildcard: 'tag1' }, nil).to_a).not_to match_array [task_one, task_two, task_three]
      end
    end
  end
end
