require 'async'

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
end
