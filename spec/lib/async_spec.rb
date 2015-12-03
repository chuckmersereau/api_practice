require 'spec_helper'

class Foo
  include Async
  include Sidekiq::Worker

  def kill(_person) end
end

describe 'Async' do
  it 'should perform a method with an id' do
    foo = double('foo')
    expect(Foo).to receive(:find).with(5).and_return(foo)
    expect(foo).to receive(:kill).with('Todd')
    Foo.new.perform(5, :kill, 'Todd')
  end

  it 'should perform a method without an id' do
    foo = Foo.new
    expect(foo).to receive(:kill).with('Todd')
    foo.perform(nil, :kill, 'Todd')
  end

  it 'can schedule jobs randomly in next 24 hours', sidekiq: :testing_disabled do
    foo = Foo.new
    expect(foo).to receive(:id) { 1 }

    Sidekiq::ScheduledSet.new.clear
    expect do
      foo.async_randomly_next_24h(:kill, 'Proc')
    end.to change(Sidekiq::ScheduledSet.new, :size).by(1)

    job = Sidekiq::ScheduledSet.new.to_a.first
    expect(job.item['class']).to eq 'Foo'
    expect(job.item['args']).to eq [1, 'kill', 'Proc']
    expect(Time.at(job.score)).to be < 24.hours.since
    expect(Time.at(job.score)).to be > Time.now
  end
end
