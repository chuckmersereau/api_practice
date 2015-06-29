require 'spec_helper'
describe AccountListExhibit do
  subject { AccountListExhibit.new(account_list, context) }
  let(:account_list) { build(:account_list) }
  let(:context) { double }
  let(:user) { create(:user) }

  before do
    2.times do
      account_list.designation_accounts << build(:designation_account)
    end
    account_list.users << user
  end

  it 'returns a designation account names for to_s' do
    expect(subject.to_s).to eq(account_list.designation_accounts.map(&:name).join(', '))
  end

  it 'returns names with balances' do
    account_list.designation_accounts << create(:designation_account, name: 'foo', balance: 5)
    allow(context).to receive(:number_to_current_currency).with(5).and_return('$5')
    expect(subject.balances(user)).to include('Balance: $5')
  end

  it 'converts null balances to 0' do
    account_list.designation_accounts << create(:designation_account, name: 'foo', balance: nil)
    allow(context).to receive(:number_to_current_currency).with(0).and_return('$0')
    expect(subject.balances(user)).to include('Balance: $0')
  end

  it 'sums the balances of multiple designation accounts' do
    account_list.designation_accounts << create(:designation_account, name: 'foo', balance: 1)
    account_list.designation_accounts << create(:designation_account, name: 'bar', balance: 2)
    allow(context).to receive(:number_to_current_currency).with(3).and_return('$3')
    expect(subject.balances(user)).to include('Balance: $3')
  end
end
