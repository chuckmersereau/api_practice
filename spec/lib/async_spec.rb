require 'async'
require 'rails_helper'

class Foo
  include Async
  include Sidekiq::Worker

  def kill(_person) end

  def self.find_by!(_var); end
end

describe 'Async' do
  let(:id) { SecureRandom.uuid }
  it 'should perform a method with an id' do
    foo = double('foo')
    allow(Foo).to receive(:find_by!).with(id: id).and_return(foo)
    expect(foo).to receive(:kill).with('Todd')
    Foo.new.perform(id, :kill, 'Todd')
  end

  it 'should perform a method without an id' do
    foo = Foo.new
    expect(foo).to receive(:kill).with('Todd')
    foo.perform(nil, :kill, 'Todd')
  end
end
