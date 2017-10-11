require 'rails_helper'

describe Coaching::Contact::TotalMonthlyPledge do
  let(:scope) { Contact.all }
  let(:account_list) { create(:account_list, settings: { currency: 'GBP' }) }
  let(:service) { described_class.new(scope, 'GBP') }

  before do
    create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 1)
    create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 2)
  end

  it 'no contacts' do
    expect(service.total).to eq 0
  end

  it 'single contact, monthly' do
    create_contact amount: 10, frequency: 1, currency: 'EUR'
    expect(service.total).to eq 20
  end

  it 'single contact, bi-monthly' do
    create_contact amount: 10, frequency: 0.5, currency: 'EUR'
    expect(service.total).to eq 40
  end

  it 'single contact, semi-monthly' do
    create_contact amount: 10, frequency: 2, currency: 'EUR'
    expect(service.total).to eq 10
  end

  it 'two contacts, monthly' do
    create_contact amount: 10, frequency: 1, currency: 'EUR'
    create_contact amount: 20, frequency: 1, currency: 'EUR'
    expect(service.total).to eq 60
  end

  it 'two contacts, bi-monthly' do
    create_contact amount: 10, frequency: 0.5, currency: 'EUR'
    create_contact amount: 20, frequency: 0.5, currency: 'EUR'
    expect(service.total).to eq 120
  end

  it 'two contacts, semi-monthly' do
    create_contact amount: 10, frequency: 2, currency: 'EUR'
    create_contact amount: 20, frequency: 2, currency: 'EUR'
    expect(service.total).to eq 30
  end

  it 'three contacts, different frequencies' do
    create_contact amount: 10, frequency: 0.5, currency: 'EUR'
    create_contact amount: 20, frequency: 1, currency: 'EUR'
    create_contact amount: 30, frequency: 2, currency: 'EUR'
    expect(service.total).to eq 110
  end

  it 'returns a result with two digits' do
    create_contact amount: 10.23456, frequency: 1, currency: 'EUR'
    expect(service.total).to eq 20.46
  end

  private

  def create_contact(args = {})
    args = Hash[args.map { |k, v| [format('pledge_%s', k), v] }]
    create(:contact, args.merge(account_list: account_list))
  end
end
