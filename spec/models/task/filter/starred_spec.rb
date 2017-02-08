require 'rails_helper'

RSpec.describe Task::Filter::Starred do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list: account_list, starred: false) }
  let!(:task_two)   { create(:task, account_list: account_list, starred: true) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { overdue: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { overdue: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { overdue: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by starred' do
      it 'filters where starred is true' do
        expect(described_class.query(tasks, { starred: true }, nil).to_a).to include(task_two)
      end
    end
  end
end
