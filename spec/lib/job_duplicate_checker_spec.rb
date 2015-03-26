require 'spec_helper'
require 'job_duplicate_checker'

class DupCheckWorker
  include Sidekiq::Worker
  include JobDuplicateChecker
end

class OtherTestWorker
  include Sidekiq::Worker
  include JobDuplicateChecker
end

describe JobDuplicateChecker do
  let(:dup_check_worker) { DupCheckWorker.new }
  let(:other_test_worker) { OtherTestWorker.new }

  context '#job_in_retries?' do
    it 'checks the retries for a matching job' do
      expect(Sidekiq::RetrySet).to receive(:new).at_least(3).times
        .and_return([double(klass: 'DupCheckWorker', args: [1, 2])])

      expect(dup_check_worker.send(:job_in_retries?, [1, 2])).to be_true
      expect(dup_check_worker.send(:job_in_retries?, [1, 3])).to be_false

      expect(other_test_worker.send(:job_in_retries?, [1, 2])).to be_false
    end
  end

  context '#older_job_running?' do
    it 'checks for jobs run at an early time or run the same time and enqueued earlier' do
      work1 = {
        'queue' => 'q', 'run_at' => 2,
        'payload' => {
          'retry' => true, 'queue' => 'q', 'backtrace' => true, 'unique' => true, 'class' => 'DupCheckWorker',
          'args' => [1, 2], 'jid' => '1', 'enqueued_at' => 1.1, 'unique_hash' => 'a'
        }
      }
      work2 = {
        'queue' => 'q', 'run_at' => 2,
        'payload' => {
          'retry' => true, 'queue' => 'q', 'backtrace' => true, 'unique' => true, 'class' => 'DupCheckWorker',
          'args' => [1, 2], 'jid' => '2', 'enqueued_at' => 1.2, 'unique_hash' => 'b'
        }
      }
      work3 = {
        'queue' => 'q', 'run_at' => 3,
        'payload' => {
          'retry' => true, 'queue' => 'q', 'backtrace' => true, 'unique' => true, 'class' => 'DupCheckWorker',
          'args' => [1, 2], 'jid' => '3', 'enqueued_at' => 1.3, 'unique_hash' => 'c'
        }
      }
      workers = [['pid1', 'thread1', work1], ['pid2', 'thread2', work2], ['pid3', 'thread3', work3]]
      expect(Sidekiq::Workers).to receive(:new).at_least(:once).and_return(workers)

      dup_check_worker.jid = '1'
      expect(dup_check_worker.send(:older_job_running?, [1, 2])).to be_false

      dup_check_worker.jid = '2'
      expect(dup_check_worker.send(:older_job_running?, [1, 2])).to be_true

      dup_check_worker.jid = '3'
      expect(dup_check_worker.send(:older_job_running?, [1, 2])).to be_true

      dup_check_worker.jid = 'not a running job id'
      expect(dup_check_worker.send(:older_job_running?, [1, 2])).to_not be_true

      dup_check_worker.jid = '1'
      expect(dup_check_worker.send(:older_job_running?, [1, 3])).to be_false

      expect(other_test_worker.send(:older_job_running?, [1, 3])).to_not be_true
    end
  end
end
