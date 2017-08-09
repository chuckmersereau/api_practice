require 'rails_helper'

describe TaskNotificationsWorker, sidekiq: :testing_disabled do
  context 'Create jobs for upcoming tasks' do
    let(:user) { create(:user, email: create(:email_address)) }
    let(:account_list) { create(:account_list, users: [user]) }
    let!(:task) do
      create(:task,
             account_list: account_list,
             start_at: 55.minutes.from_now,
             notification_time_before: 3,
             notification_time_unit: 1)
    end

    it 'queues the job' do
      clear_uniqueness_locks
      Sidekiq::ScheduledSet.new.clear
      expect do
        subject.perform
      end.to change(Sidekiq::ScheduledSet.new, :size).by(1)
    end
  end
end
