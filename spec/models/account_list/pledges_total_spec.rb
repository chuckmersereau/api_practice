require 'spec_helper'

describe AccountList::PledgesTotal do
  let(:account_list) { create(:account_list) }

  before do
    allow($rollout).to receive(:active?) { true }
  end

  it 'defaults unknown currency rates to 1' do
    rate = AccountList::PledgesTotal.new(account_list, account_list.contacts).latest_rate('ANY')
    expect(rate).to eq(1)
  end

  it 'calculates total pledges with no Financial Partners' do
    create(:contact, account_list: account_list, pledge_amount: 15, pledge_currency: 'USD', status: 'Partner - Special')
    create(:contact, account_list: account_list, pledge_amount: 10, pledge_currency: 'USD', status: '')

    expect(account_list.total_pledges).to eq(0)
  end

  it 'calculates total pledges' do
    create(:contact, account_list: account_list, pledge_amount: 15, pledge_currency: 'USD', status: 'Partner - Financial')
    create(:contact, account_list: account_list, pledge_amount: 10, pledge_currency: 'USD', status: '')

    expect(account_list.total_pledges).to eq(15)
  end

  it 'calculates total pledges with currency conversion' do
    account_list.update(currency: 'EUR')
    create(:currency_rate, rate: 0.8, exchanged_on: '2016-02-15', code: 'EUR')
    create(:currency_rate, rate: 0.75, exchanged_on: '2016-01-15', code: 'EUR')
    create(:currency_rate, rate: 75.20, exchanged_on: '2016-02-15', code: 'RUB')

    create(:contact, account_list: account_list, pledge_amount: 15, pledge_currency: 'USD', status: 'Partner - Financial')
    create(:contact, account_list: account_list, pledge_amount: 95, pledge_currency: 'RUB', status: 'Partner - Financial')

    expect(account_list.total_pledges).to eq(13.01)
  end
end