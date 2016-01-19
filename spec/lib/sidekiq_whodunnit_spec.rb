require 'spec_helper'

describe SidekiqWhodunnit do
  it 'tracks the sidekiq job info to be accessed later in the job' do
    job = {
      'class' => 'Worker', 'enqueued_at' => 1,
      'args' => [1, :a, { c: 'hi' }], 'jid' => '1', 'x' => 2
    }

    block_called = false
    SidekiqWhodunnit.new.call(double, job, double) do
      block_called = true
    end
    expect(block_called).to be true

    expect(PaperTrail.whodunnit).to eq 'Worker [1, :a, {:c=>"hi"}]'
  end
end
