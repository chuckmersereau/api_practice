require 'rails_helper'

describe SidekiqCronLoader do
  it 'has all existing worker classes with correct perform methods' do
    Sidekiq.logger.level = Logger::ERROR
    SidekiqCronLoader.new.load!
    jobs = Sidekiq::Cron::Job.all
    expect(jobs.size).to eq SidekiqCronLoader::SIDEKIQ_CRON_HASH.size
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
