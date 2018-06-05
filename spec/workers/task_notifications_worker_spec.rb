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
             notification_time_unit: 1,
             notification_type: 'both')
    end

    before do
      clear_uniqueness_locks
    end

    it 'queues the job' do
      expect { subject.perform }.to change(Sidekiq::ScheduledSet.new, :size).by(1)
    end

    it 'does not query a job if mobile only' do
      task.update(notification_type: 'mobile')

      expect { subject.perform }.to_not change(Sidekiq::ScheduledSet.new, :size)
    end
  end
end
