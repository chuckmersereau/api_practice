require 'spec_helper'

describe AsyncScheduler, sidekiq: :testing_disabled do
  context '.schedule_over_24h' do
    it 'can schedule jobs evenly in next 24 hours' do
      clear_uniqueness_locks

      al1 = create(:account_list)
      al2 = create(:account_list)
      al3 = create(:account_list)

      Sidekiq::ScheduledSet.new.clear

      account_lists_relation = AccountList.where(id: [al1.id, al2.id, al3.id])
      expect do
        AsyncScheduler.schedule_over_24h(account_lists_relation, :import_data)
      end.to change(Sidekiq::ScheduledSet.new, :size).by(3)

      job1, job2, job3 = Sidekiq::ScheduledSet.new.to_a

      expect(job1.item['class']).to eq 'AccountList'
      expect(job1.item['args']).to eq [al1.id, 'import_data']
      expect(job1.score).to be_within(1.0).of Time.now.to_i
      expect(job1.queue).to eq 'import'

      expect(job2.item['class']).to eq 'AccountList'
      expect(job2.item['args']).to eq [al2.id, 'import_data']
      expect(job2.score).to be_within(1.0).of 8.hours.since.to_i

      expect(job3.item['class']).to eq 'AccountList'
      expect(job3.item['args']).to eq [al3.id, 'import_data']
      expect(job3.score).to be_within(1.0).of 16.hours.since.to_i
    end

    it 'does nothing for an empty relation' do
      AsyncScheduler.schedule_over_24h(AccountList.where('1 = 0'), :import_data)
    end

    it 'schedules jobs on the specified queue' do
      clear_uniqueness_locks
      Sidekiq::ScheduledSet.new.clear
      Sidekiq::Queue.new.clear
      account_list = create(:account_list)

      AsyncScheduler.schedule_over_24h(AccountList.where(id: account_list.id),
                                       :import_data, :default)

      job = Sidekiq::ScheduledSet.new.to_a.first
      expect(job.queue).to eq 'default'
    end
  end
end
