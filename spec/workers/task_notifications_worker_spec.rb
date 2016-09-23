require 'spec_helper'

describe TaskNotificationsWorker, sidekiq: :testing_disabled do
  context 'Create jobs for upcoming tasks' do
    let!(:task) { create(:task, start_at: 55.minutes.from_now, notification_time_before: 3, notification_time_unit: 1) }

    it 'queues the job' do
      clear_uniqueness_locks
      Sidekiq::ScheduledSet.new.clear
      expect do
        subject.perform
      end.to change(Sidekiq::ScheduledSet.new, :size).by(1)
    end
  end
end
