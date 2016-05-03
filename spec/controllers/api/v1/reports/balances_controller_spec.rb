require 'spec_helper'

describe Api::V1::Reports::BalancesController do
  context '#show' do
    it 'renders designations' do
      account_list = create(:account_list, salary_currency: 'GBP')
      org = create(:organization, default_currency_code: 'EUR', name: 'TestOrg')
      designation_account =
        create(:designation_account,
               balance: 10, designation_number: 'A1', organization: org,
               balance_updated_at: Time.new(2016, 4, 18, 1, 0, 0))
      create(:currency_rate, rate: 0.7, code: 'GBP', exchanged_on: Date.yesterday)
      create(:currency_rate, rate: 0.89, code: 'EUR', exchanged_on: Date.yesterday)
      account_list.designation_accounts << designation_account
      user = create(:user)
      user.account_lists << account_list
      login(user)

      get :show

      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json['total_currency']).to eq 'GBP'
      expect(json['total_currency_symbol']).to eq '£'
      expect(json['designations'].size).to eq 1
      designation = json['designations'][0]
      expect(designation['organization_name']).to eq 'TestOrg'
      expect(designation['designation_number']).to eq 'A1'
      expect(designation['currency']).to eq 'EUR'
      expect(designation['currency_symbol']).to eq '€'
      expect(designation['converted_balance'].to_f).to be_within(0.1).of(7.8)
      expect(designation['exchange_rate'].to_f).to be_within(0.1).of(0.78)
      expect(Time.parse(designation['balance_updated_at']))
        .to eq Time.new(2016, 4, 18, 1, 0, 0)
    end
  end
end
