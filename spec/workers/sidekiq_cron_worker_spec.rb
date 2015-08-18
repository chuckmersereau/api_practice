require 'spec_helper'

describe SidekiqCronWorker do
  class TestJob
  end

  it 'calls the specified static method' do
    expect(TestJob).to receive(:test)
    Sidekiq::Testing.inline! do
      SidekiqCronWorker.perform_async('TestJob.test')
    end
  end
end
