require 'rails_helper'

describe AccountList::PledgesTotal do
  let(:account_list) { create(:account_list, salary_organization_id: create(:organization).id) }

  it 'defaults unknown currency rates to 1' do
    rate = described_class.new(account_list, account_list.contacts).latest_rate('ANY')
    expect(rate).to eq(1)
  end

  let!(:contact1) do
    create(:contact,
           account_list: account_list,
           pledge_amount: 15,
           pledge_currency: 'USD',
           status: 'Partner - Financial')
  end
  let!(:contact2) do
    create(:contact,
           account_list: account_list,
           pledge_amount: 10,
           pledge_currency: 'USD',
           status: 'Partner - Financial')
  end

  it 'calculates total pledges with no Financial Partners' do
    contact1.update(status: 'Partner - Special')
    contact2.update(status: '')
    expect(account_list.total_pledges).to eq(0)
  end

  it 'calculates total pledges' do
    expect(account_list.total_pledges).to eq(25)
  end

  context 'multi-currency' do
    before do
      account_list.update(currency: 'EUR')
      contact2.update(pledge_amount: 95, pledge_currency: 'RUB')
      create(:currency_rate, rate: 0.8, exchanged_on: '2016-02-15', code: 'EUR')
      create(:currency_rate, rate: 0.75, exchanged_on: '2016-01-15', code: 'EUR')
      create(:currency_rate, rate: 75.20, exchanged_on: '2016-02-15', code: 'RUB')
    end

    it 'calculates total pledges with currency conversion' do
      expect(account_list.total_pledges).to eq(16.26)
    end
  end
end
