require 'rails_helper'

RSpec.describe Task::Filter::DateRange do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:task_last_week) { create(:task, account_list: account_list, completed: true, completed_at: 1.week.ago) }
  let!(:task_last_month) { create(:task, account_list: account_list, completed: true, completed_at: 1.month.ago) }
  let!(:task_last_year) { create(:task, account_list: account_list, completed: true, completed_at: 1.year.ago) }
  let!(:task_last_two_years) { create(:task, account_list: account_list, completed: true, completed_at: 2.years.ago) }
  let!(:task_overdue) { create(:task, account_list: account_list, completed: false, start_at: 1.day.ago) }
  let!(:task_today) { create(:task, account_list: account_list, completed: false, start_at: 1.minute.from_now) }
  let!(:task_tomorrow) { create(:task, account_list: account_list, completed: false, start_at: 1.day.from_now) }
  let!(:task_next_week) { create(:task, account_list: account_list, completed: false, start_at: 1.week.from_now) }
  let!(:task_no_date) { create(:task, account_list: account_list, start_at: nil) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { date_range: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { date_range: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { date_range: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by date_range' do
      it 'filters where task completed last_week' do
        expect(described_class.query(tasks, { date_range: 'last_week' }, nil).to_a).to eq([task_last_week])
      end
      it 'filters where task completed last_month' do
        expect(described_class.query(tasks, { date_range: 'last_month' }, nil).to_a).to eq([task_last_month])
      end
      it 'filters where task completed last_year' do
        expect(described_class.query(tasks, { date_range: 'last_year' }, nil).to_a).to eq([task_last_year])
      end
      it 'filters where task completed last_two_years' do
        expect(described_class.query(tasks, { date_range: 'last_two_years' }, nil).to_a).to eq([task_last_two_years])
      end
      it 'filters where task start_at overdue' do
        expect(described_class.query(tasks, { date_range: 'overdue' }, nil).to_a).to eq([task_overdue])
      end
      it 'filters where task start_at today' do
        expect(described_class.query(tasks, { date_range: 'today' }, nil).to_a).to eq([task_today])
      end
      it 'filters where task start_at tomorrow' do
        expect(described_class.query(tasks, { date_range: 'tomorrow' }, nil).to_a).to eq([task_tomorrow])
      end
      it 'filters where task start_at future' do
        expect(described_class.query(tasks, { date_range: 'future' }, nil).to_a).to match_array([task_today, task_tomorrow, task_next_week])
      end
      it 'filters where task start_at upcoming' do
        expect(described_class.query(tasks, { date_range: 'upcoming' }, nil).to_a).to match_array([task_tomorrow, task_next_week])
      end
      it 'filters where task start_at upcoming' do
        expect(described_class.query(tasks, { date_range: 'no_date' }, nil).to_a).to eq([task_no_date])
      end
    end
  end
end
