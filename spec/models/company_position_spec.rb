require 'spec_helper'

describe CompanyPosition do
  it 'should return the position name for to_s' do
    expect(CompanyPosition.new(position: 'foo').to_s).to eq('foo')
  end
end
