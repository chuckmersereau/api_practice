require 'rails_helper'

RSpec.describe Task::Filter::Ids do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list_id: account_list.id) }
  let!(:task_two)   { create(:task, account_list_id: account_list.id) }
  let!(:task_three) { create(:task, account_list_id: account_list.id) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { ids: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { ids: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { ids: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by id' do
      it 'filters multiple ids' do
        expect(described_class.query(tasks, { ids: [task_one.id, task_two.id] }, nil).to_a).to include(task_one, task_two)
      end
      it 'filters a single id' do
        expect(described_class.query(tasks, { ids: task_one.id }, nil).to_a).to include(task_one)
      end
    end
  end
end
