require 'spec_helper'

RSpec.describe Task::Analytics, type: :service do
  let(:today)        { Date.current }
  let(:account_list) { create(:account_list) }

  describe '#initialize' do
    it 'initializes with a tasks collection' do
      tasks = double(:tasks)

      analytics = Task::Analytics.new(tasks)
      expect(analytics.tasks).to eq tasks
    end
  end

  describe 'counts' do
    let(:account_list)       { create(:account_list) }
    let(:tasks)              { account_list.tasks }

    let(:activity_type_keys) do
      Task::TASK_ACTIVITIES.map { |type| type.parameterize.underscore.to_sym }
    end

    before do
      activity_type_keys.each do |type_key|
        create(:task, type_key, :complete, :today, account_list: account_list)
        create(:task, type_key, :complete, :yesterday, account_list: account_list)
        create(:task, type_key, :incomplete, :tomorrow, account_list: account_list)
        create(:task, type_key, :incomplete, :today, account_list: account_list)
        create(:task, type_key, :overdue, account_list: account_list)
      end
    end

    let(:analytics) { Task::Analytics.new(tasks) }

    describe '#tasks_overdue_or_due_today_counts' do
      it 'pulls the counts for the tasks that are overdue or due today' do
        counts_data = analytics.tasks_overdue_or_due_today_counts
        labels      = counts_data.map { |count_data| count_data[:label] }

        expect(labels).to match_array Task::TASK_ACTIVITIES

        counts_data.each do |count_data|
          expect(count_data[:count]).to eq 2
        end
      end

      context 'without any tasks' do
        let(:tasks) { create(:account_list).tasks }

        it 'still returns an array of objects of all the labels' do
          counts_data = analytics.tasks_overdue_or_due_today_counts
          labels      = counts_data.map { |count_data| count_data[:label] }

          expect(labels).to match_array Task::TASK_ACTIVITIES

          counts_data.each do |count_data|
            expect(count_data[:count]).to eq 0
          end
        end
      end
    end

    describe '#total_tasks_due_count' do
      it 'pulls the count for all the tasks that are overdue' do
        expected_count = activity_type_keys.count * 2
        expect(analytics.total_tasks_due_count).to eq expected_count
      end
    end
  end

  describe 'newsletters' do
    let(:account_list) { create(:account_list) }

    let!(:first_complete_email_newsletter) do
      create(:task,
             :newsletter_email,
             :complete,
             account_list: account_list,
             completed_at: 1.day.ago)
    end

    let!(:second_complete_email_newsletter) do
      create(:task,
             :newsletter_email,
             :complete,
             account_list: account_list,
             completed_at: Date.current)
    end

    let!(:incomplete_email_newsletter) do
      create(:task,
             :newsletter_email,
             :incomplete,
             account_list: account_list)
    end

    let!(:first_complete_physical_newsletter) do
      create(:task,
             :newsletter_physical,
             :complete,
             account_list: account_list,
             completed_at: 1.day.ago)
    end

    let!(:second_complete_physical_newsletter) do
      create(:task,
             :newsletter_physical,
             :complete,
             account_list: account_list,
             completed_at: Date.current)
    end

    let!(:incomplete_physical_newsletter) do
      create(:task,
             :newsletter_physical,
             :incomplete,
             account_list: account_list)
    end

    let(:analytics) { Task::Analytics.new(account_list.tasks) }

    describe '#last_electronic_newsletter_completed_at' do
      it "returns the last electronic newsletter's completed_at time" do
        expect(analytics.last_electronic_newsletter_completed_at)
          .to eq second_complete_email_newsletter.completed_at
      end
    end

    describe '#last_physical_newsletter_completed_at' do
      it "returns the last physical newsletter's completed_at time" do
        expect(analytics.last_physical_newsletter_completed_at)
          .to eq second_complete_physical_newsletter.completed_at
      end
    end
  end
end
