require 'rails_helper'

RSpec.describe Task::Filter::UpdatedAt do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one) { create(:task, account_list: account_list, updated_at: 1.day.ago) }
  let!(:task_two) { create(:task, account_list: account_list, updated_at: 2.days.ago) }

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
        expect(described_class.query(tasks, { updated_at: {} }, nil)).to eq nil
        expect(described_class.query(tasks, { updated_at: [] }, nil)).to eq nil
        expect(described_class.query(tasks, { updated_at: '' }, nil)).to eq nil
      end
    end

    context 'filter with updated_at value' do
      it 'returns only tasks that have the updated_at value' do
        expect(described_class.query(tasks, { updated_at: task_one.updated_at }, nil).to_a).to eq [task_one]
      end
    end

    context 'filter with updated_at range' do
      let(:one_day_ago)  { 1.day.ago.beginning_of_day..1.day.ago.end_of_day }
      let(:last_two_days) { 2.days.ago.beginning_of_day..1.day.ago.end_of_day }

      it 'returns only tasks that are within the updated_at range' do
        expect(described_class.query(tasks, { updated_at: one_day_ago }, nil).to_a).to eq [task_one]
        expect(described_class.query(tasks, { updated_at: last_two_days }, nil).to_a).to match_array [task_one, task_two]
      end
    end
  end
end
