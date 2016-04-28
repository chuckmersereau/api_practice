require 'spec_helper'

describe Api::V1::Reports::YearDonationsController, '#show' do
  around do |example|
    travel_to Date.new(2016, 4, 28) do
      example.run
    end
  end

  it 'returns json with donation and donor information' do
    create(:currency_rate, code: 'GBP', rate: 0.6, exchanged_on: Date.current)
    create(:currency_rate, code: 'EUR', rate: 0.9, exchanged_on: Date.current)
    account_list = create(:account_list, salary_currency: 'EUR')
    designation_account = create(:designation_account)
    account_list.designation_accounts << designation_account
    donor_account = create(:donor_account)
    contact = create(:contact,
                     account_list: account_list,
                     name: 'John', status: 'Partner - Special',
                     pledge_amount: 10, pledge_frequency: 1,
                     pledge_currency: 'GBP')
    contact.donor_accounts << donor_account
    create(:donation, tendered_amount: 10, tendered_currency: 'GBP',
                      donation_date: Date.current, donor_account: donor_account,
                      designation_account: designation_account)
    user = create(:user)
    user.account_lists << account_list
    login(user)

    get :show

    expect(response).to be_success
    report_info = JSON.parse(response.body).deep_symbolize_keys[:report_info]
    expect(report_info[:donors]).to eq(
      [{
        id: contact.id, name: 'John', pledge_amount: 10,
        pledge_frequency: 'Monthly', pledge_currency: 'GBP',
        status: 'Partner - Special',
        late_by_30_days: false, late_by_60_days: false
      }]
    )
    expect(report_info[:donations]).to eq(
      [{
        liklihood_type: 'received', contact_id: contact.id,
        amount: 10.0, currency: 'GBP', donation_date: '2016-04-28',
        currency_symbol: '£', converted_amount: 15.0,
        converted_currency: 'EUR', converted_currency_symbol: '€'
      }]
    )
  end
end
