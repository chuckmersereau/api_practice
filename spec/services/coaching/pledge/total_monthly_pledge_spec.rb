require 'rails_helper'

describe Coaching::Pledge::TotalMonthlyPledge do
  let(:scope) { Pledge.all }
  let(:account_list) { create(:account_list, settings: { currency: 'GBP' }) }
  let(:service) { described_class.new(scope, 'GBP') }

  before do
    create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 1)
    create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 2)
  end

  it 'no pledges' do
    expect(service.total).to eq 0
  end

  it 'single pledge' do
    create_pledge amount: 10, amount_currency: 'EUR'
    expect(service.total).to eq 20
  end

  it 'two pledges' do
    create_pledge amount: 10, amount_currency: 'EUR'
    create_pledge amount: 20, amount_currency: 'EUR'
    expect(service.total).to eq 60
  end

  it 'three pledges' do
    create_pledge amount: 10, amount_currency: 'EUR'
    create_pledge amount: 20, amount_currency: 'EUR'
    create_pledge amount: 30, amount_currency: 'EUR'
    expect(service.total).to eq 120
  end

  it 'returns a result with two digits' do
    create_pledge amount: 10.23456, amount_currency: 'EUR'
    expect(service.total).to eq 20.47
  end

  private

  def create_pledge(args = {})
    create(:pledge, args.merge(account_list: account_list))
  end
end
