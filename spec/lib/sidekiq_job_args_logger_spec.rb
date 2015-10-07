require 'spec_helper'

describe SidekiqJobArgsLogger do
  it 'logs job arguments and yields to the passed in block' do
    job = {
      'class' => 'A', 'enqueued_at' => 1, 'args' => [1], 'jid' => '1', 'x' => 2
    }

    logger = double
    expect(Sidekiq).to receive(:logger) { logger }
    expect(logger).to receive(:info).with('args' => [1], 'x' => 2)

    block_called = false
    subject.call(double, job, double) do
      block_called = true
    end
    expect(block_called).to be true
  end
end
