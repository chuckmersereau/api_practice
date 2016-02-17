require 'spec_helper'

describe AccountList::PledgesTotal do
  let(:account_list) { create(:account_list) }

  it 'assign contact currency' do
    contact = create(:contact, account_list: account_list, pledge_currency: 'EUR')
    expect(contact.pledge_currency).to eq('EUR')
  end

  it 'total pledges calculation' do
    create(:contact, account_list: account_list, pledge_amount: 15, pledge_currency: 'USD', status: 'Partner - Financial')
    create(:contact, account_list: account_list, pledge_amount: 10, pledge_currency: 'USD', status: '')

    expect(account_list.total_pledges).to eq(15)
  end

  it 'total pledges currency conversion' do
    create(:currency_rate, rate: 0.8, exchanged_on: '2016-02-15', code: 'EUR')
    create(:currency_rate, rate: 0.75, exchanged_on: '2016-01-15', code: 'EUR')
    create(:currency_rate, rate: 75.20, exchanged_on: '2016-02-15', code: 'RUB')

    create(:contact, account_list: account_list, pledge_amount: 15, pledge_currency: 'EUR', status: 'Partner - Financial')
    create(:contact, account_list: account_list, pledge_amount: 95, pledge_currency: 'RUB', status: 'Partner - Financial')

    expect(account_list.total_pledges).to eq(20.01)
  end
end
