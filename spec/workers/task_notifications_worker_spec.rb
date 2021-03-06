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
      Sidekiq::ScheduledSet.new.clear
    end

    it 'queues the job' do
      expect { subject.perform }.to change(Sidekiq::ScheduledSet.new, :size).by(1)
    end

    it 'queues the job into the mailer queue' do
      subject.perform

      expect(Sidekiq::ScheduledSet.new.to_a.last.queue).to eq 'mailers'
    end

    it 'does not query a job if mobile only' do
      task.update(notification_type: 'mobile')

      expect { subject.perform }.to_not change(Sidekiq::ScheduledSet.new, :size)
    end

    it 'will queue a task and use the default time unit if it is missing' do
      task.update(notification_time_unit: nil, notification_scheduled: nil)
      notifier = TaskNotificationsWorker.new
      start_time = task.start_at - task.notification_time_before.send('minutes')
      expect(notifier.determine_start_time(task)).to eq(start_time)
    end
  end
end
