require 'spec_helper'

describe SidekiqCronWorker do
  class TestJob
  end

  it 'calls the specified static method' do
    expect(TestJob).to receive(:test)
    SidekiqCronWorker.new.perform('TestJob.test')
  end
end
