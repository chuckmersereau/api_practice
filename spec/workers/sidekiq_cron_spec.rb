require 'spec_helper'

describe 'Sidekiq cron' do
  it 'has all existing worker classes with correct perform methods' do
    Sidekiq.logger.level = Logger::ERROR
    load_sidekiq_cron_hash
    jobs = Sidekiq::Cron::Job.all
    expect(jobs.size).to eq SIDEKIQ_CRON_HASH.size
    expect(jobs.all?(&:valid?)).to be true
    jobs.each do |job|
      klass = job.klass.constantize
      expect(klass).to be_present
      perform = klass.instance_method(:perform)
      expect(perform).to be_present
      expect(perform.arity == -1 || perform.arity == job.args.size).to be true
    end
  end
end
