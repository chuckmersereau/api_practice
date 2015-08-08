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

    allow(context).to receive(:number_to_current_currency) { |x| "$#{x}" }
  end

  it 'returns a designation account names for to_s' do
    expect(subject.to_s).to eq(account_list.designation_accounts.map(&:name).join(', '))
  end

  it 'returns names with balances' do
    account_list.designation_accounts << create(:designation_account, name: 'foo', balance: 5)
    expect(subject.balances(user)).to include('Balance: $5')
  end

  it 'converts null balances to 0' do
    account_list.designation_accounts << create(:designation_account, name: 'foo', balance: nil)
    expect(subject.balances(user)).to include('Balance: $0')
  end

  it 'sums the balances of multiple designation accounts' do
    account_list.designation_accounts << create(:designation_account, name: 'foo', balance: 1)
    account_list.designation_accounts << create(:designation_account, name: 'bar', balance: 2)
    expect(subject.balances(user)).to include('Balance: $3')
  end

  # This case occured during testing for the account list sharing. It may be
  # rare, but we may as well check for it.
  it 'treats and account list entry without a designation account as zero balance' do
    account_list_entry = create(:account_list_entry, designation_account: nil)
    account_list.account_list_entries << account_list_entry
    expect(subject.balances(user)).to include('Balance: $0')
  end
end
