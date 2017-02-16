require 'rails_helper'

RSpec.describe Task::Filter::Completed do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list: account_list, completed: true) }
  let!(:task_two)   { create(:task, account_list: account_list, completed: false) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(default_selection: nil,
                                                                name: :completed,
                                                                parent: nil,
                                                                priority: 1,
                                                                title: 'Completed',
                                                                type: 'single_checkbox')
    end
  end

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { completed: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { completed: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { completed: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by activity_type' do
      it 'filters completed' do
        expect(described_class.query(tasks, { completed: true }, nil).to_a).to include(task_one)
      end
    end
  end
end
