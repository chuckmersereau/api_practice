require 'spec_helper'

describe AsyncScheduler do
  context '.schedule_over_24h' do
    it 'can schedule jobs randomly in next 24 hours', sidekiq: :testing_disabled do
      clear_uniqueness_locks

      al1 = create(:account_list)
      al2 = create(:account_list)
      al3 = create(:account_list)

      Sidekiq::ScheduledSet.new.clear
      Sidekiq::Queue.new('import').clear

      account_lists_relation = AccountList.where(id: [al1.id, al2.id, al3.id])
      expect do
        AsyncScheduler.schedule_over_24h(account_lists_relation, :import_data)
      end.to change(Sidekiq::ScheduledSet.new, :size).by(2)

      # The first job is queued right away and the rest are scheduled evenly
      job1 = Sidekiq::Queue.new('import').to_a.last
      expect(job1.item['class']).to eq 'AccountList'
      expect(job1.item['args']).to eq [al1.id, 'import_data']

      job2, job3 = Sidekiq::ScheduledSet.new.to_a

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
  end
end
