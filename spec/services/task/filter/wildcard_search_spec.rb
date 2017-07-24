require 'rails_helper'

RSpec.describe Task::Filter::WildcardSearch do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let(:contact) { create(:contact, name: 'Contact Name') }

  let!(:task_one)   { create(:task, account_list_id: account_list.id, subject: 'I have Subject1 in here', tag_list: 'tag1,tag2') }
  let!(:task_two)   { create(:task, account_list_id: account_list.id, subject: 'subject2 is here', tag_list: 'tag1', contacts: [contact]) }
  let!(:task_three) { create(:task, account_list_id: account_list.id, subject: 'Subject3', tag_list: 'tag3', contacts: [contact]) }
  let!(:task_four)  { create(:task, account_list_id: account_list.id, subject: 'Subject4', comments: [build(:activity_comment, body: 'Commented right now!')]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'with wildcard subject' do
      it 'returns all tasks that match the subject' do
        expect(described_class.query(tasks, { wildcard_search: 'subject1' }, nil).to_a).to eq [task_one]
        expect(described_class.query(tasks, { wildcard_search: 'subject1' }, nil).to_a).not_to match_array [task_one, task_two, task_three]
      end
    end

    context 'with a single wildcard tag (partial or not)' do
      it 'returns all tasks that match the tag' do
        expect(described_class.query(tasks, { wildcard_search: 'tag1' }, nil).to_a).to match_array [task_one, task_two]
        expect(described_class.query(tasks, { wildcard_search: 'tag' }, nil).to_a).to match_array [task_one, task_two, task_three]
      end
    end

    context 'with a comment body containing the string' do
      it 'returns all tasks with a matching comment' do
        expect(described_class.query(tasks, { wildcard_search: 'commented right' }, nil).to_a).to match_array [task_four]
        expect(described_class.query(tasks, { wildcard_search: 'now' }, nil).to_a).to match_array [task_four]
      end
    end

    context 'with a contact name containing the string' do
      it 'returns all tasks with a matching contact' do
        expect(described_class.query(tasks, { wildcard_search: 'contact name' }, nil).to_a).to match_array [task_two, task_three]
        expect(described_class.query(tasks, { wildcard_search: 'act na' }, nil).to_a).to match_array [task_two, task_three]
      end
    end
  end
end
