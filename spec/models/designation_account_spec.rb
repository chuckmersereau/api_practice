require 'spec_helper'

describe DesignationAccount do
  it 'should return designation_number for to_s' do
    expect(DesignationAccount.new(designation_number: 'foo').to_s).to eq('foo')
  end

  it "should return a user's first account list" do
    account_list = double('account_list')
    user = double('user', account_lists: [account_list])
    da = DesignationAccount.new
    da.stub(:account_lists).and_return([account_list])
    expect(da.account_list(user)).to eq(account_list)
  end
end
