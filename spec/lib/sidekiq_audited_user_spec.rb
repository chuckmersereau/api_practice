require 'spec_helper'

describe SidekiqAuditedUser do
  class Worker
  end

  it 'tracks the sidekiq job info to be accessed later in the job' do
    job = {
      'class' => 'Worker', 'enqueued_at' => 1,
      'args' => [1, :a, { c: 'hi' }], 'jid' => '1', 'x' => 2
    }
    expect do |block|
      SidekiqAuditedUser.new.call(double, job, double, &block)
    end.to yield_control
    expect(::Audited.store[:audited_user]).to be_a(Worker)
  end
end
