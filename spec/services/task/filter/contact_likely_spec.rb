require 'rails_helper'

RSpec.describe Task::Filter::ContactLikely do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id, likely_to_give: 'Least Likely') }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id, likely_to_give: 'Likely') }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id, likely_to_give: 'Most Likely') }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id, likely_to_give: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [contact_four]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { referrer: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { referrer: [] }, account_list)).to eq(nil)
      end
    end

    context 'filter by no likely to give' do
      it 'returns only tasks with contacts that have no likely to give' do
        expect(described_class.query(tasks, { contact_likely: 'none' }, account_list).to_a).to eq [task_four]
      end
    end

    context 'filter by likely to give' do
      it 'filters multiple likely to give' do
        expect(described_class.query(tasks, { contact_likely: 'Least Likely, Likely' }, account_list).to_a).to match_array [task_one, task_two]
      end
      it 'filters a single likely to give' do
        expect(described_class.query(tasks, { contact_likely: 'Most Likely' }, account_list).to_a).to eq [task_three]
      end
    end

    context 'multiple filters' do
      it 'returns contacts matching multiple filters' do
        expect(described_class.query(tasks, { contact_likely: 'none, Most Likely, Likely' }, account_list).to_a).to match_array [task_two, task_three, task_four]
      end
    end
  end
end
