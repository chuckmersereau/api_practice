require 'rails_helper'

RSpec.describe Task::Filter::NoDate do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list: account_list, no_date: true) }
  let!(:task_two)   { create(:task, account_list: account_list, no_date: false) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { no_date: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { no_date: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { no_date: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by no_date' do
      it 'filters where no_date is true' do
        expect(described_class.query(tasks, { no_date: true }, nil).to_a).to include(task_one)
      end
    end
  end
end
