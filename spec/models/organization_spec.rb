require 'spec_helper'

describe Organization do
  it 'should return the org name for to_s' do
    expect(Organization.new(name: 'foo').to_s).to eq('foo')
  end
end
