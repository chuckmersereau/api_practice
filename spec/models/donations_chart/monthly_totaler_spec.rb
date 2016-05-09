require 'spec_helper'

describe DonationsChart::MonthlyTotaler, '#monthly_totals' do
  let(:account_list) { create(:account_list, salary_currency: 'EUR') }
  let(:designation_account) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:contact) { create(:contact, account_list: account_list) }

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  around do |example|
    travel_to(Date.new(2016, 4, 30)) { example.run }
  end

  it 'groups the donations by month and gives converted totals' do
    create(:currency_rate, code: 'EUR', rate: 0.7, exchanged_on: Date.new(2016, 3, 1))
    create(:currency_rate, code: 'EUR', rate: 0.9, exchanged_on: Date.new(2016, 4, 1))
    add_donation('EUR', 50, Date.new(2016, 4, 1))
    add_donation('EUR', 25, Date.new(2016, 4, 20))
    add_donation('EUR', 40, Date.new(2016, 2, 1))
    add_donation('USD', 25, Date.new(2016, 2, 2))
    add_donation('USD', 30, Date.new(2016, 2, 15))

    totaler = DonationsChart::MonthlyTotaler.new(account_list)

    expect(totaler.months_back).to eq 2
    totals = totaler.totals
    expect(totals[0][:currency]).to eq 'EUR'
    expect(totals[0][:total_amount]).to eq 115
    expect(totals[0][:total_converted]).to eq 115
    expect(totals[0][:month_totals].size).to eq 3
    eur_month_totals = totals[0][:month_totals]
    expect(eur_month_totals[0][:amount]).to eq 40
    expect(eur_month_totals[0][:converted]).to eq 40
    expect(eur_month_totals[1][:amount]).to eq 0
    expect(eur_month_totals[1][:converted]).to eq 0
    expect(eur_month_totals[2][:amount]).to eq 75
    expect(eur_month_totals[2][:converted]).to eq 75
    expect(totals[1][:currency]).to eq 'USD'
    expect(totals[1][:total_amount]).to eq 55
    expect(totals[1][:total_converted]).to be_within(0.1).of(38.5)
    expect(totals[1][:month_totals].size).to eq 3
    usd_month_totals = totals[1][:month_totals]
    expect(usd_month_totals[0][:amount]).to eq 55
    expect(usd_month_totals[0][:converted]).to be_within(0.1).of(38.5)
  end

  def add_donation(currency, amount, date)
    create(:donation, donor_account: donor_account, designation_account: designation_account,
                      currency: currency, amount: amount, donation_date: date)
  end

  it 'excludes donations with blank currencies' do
    create(:donation, donor_account: donor_account, currency: nil, amount: 10,
                      designation_account: designation_account,
                      donation_date: Date.new(2016, 4, 1))

    totaler = DonationsChart::MonthlyTotaler.new(account_list)

    expect(totaler.totals).to be_empty
  end
end
