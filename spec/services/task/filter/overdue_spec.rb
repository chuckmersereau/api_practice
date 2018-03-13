require 'rails_helper'

RSpec.describe Task::Filter::Overdue do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:task_one)   { create(:task, account_list: account_list, start_at: Time.current.tomorrow) }
  let!(:task_two)   { create(:task, account_list: account_list, start_at: Time.current.yesterday) }

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

    context 'filter by overdue' do
      it 'filters where overdue is true' do
        expect(described_class.query(tasks, { overdue: true }, nil).to_a).to include(task_two)
      end
    end
  end
end
