require 'rails_helper'

RSpec.describe Reports::DonationMonthlyTotals do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:designation_account) { create(:designation_account, account_lists: [account_list]) }
  let!(:donor_account) { create(:donor_account) }
  let!(:contact) { create(:contact, account_list: account_list, donor_accounts: [donor_account]) }

  let!(:cad_donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      amount: 3, currency: 'CAD',
                      donation_date: 6.months.ago + 1.day)
  end

  let!(:eur_donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      amount: 2, currency: 'EUR',
                      donation_date: 6.months.ago + 20.days)
  end

  before do
    account_list.update(salary_currency: 'NZD')
    create(:currency_rate, exchanged_on: 6.months.ago + 1.day, code: 'CAD', rate: 1.1)
    create(:currency_rate, exchanged_on: 6.months.ago + 1.day, code: 'NZD', rate: 0.7)
    create(:currency_rate, exchanged_on: 6.months.ago + 20.days, code: 'EUR', rate: 2.2)
    create(:currency_rate, exchanged_on: 6.months.ago + 20.days, code: 'NZD', rate: 0.8)
  end

  subject do
    described_class.new(account_list: account_list,
                        start_date: 6.months.ago,
                        end_date: 5.months.ago)
  end

  context 'donation_totals_by_month' do
    let(:expected_donation_amounts_by_month) do
      [
        {
          month: 6.months.ago.beginning_of_month.to_date,
          totals_by_currency: [
            {
              donor_currency: 'EUR',
              total_in_donor_currency: 2.0,
              converted_total_in_salary_currency:
                CurrencyRate.convert_on_date(
                  amount: 2.0,
                  date: 6.months.ago + 20.days,
                  from: 'EUR',
                  to: account_list.salary_currency
                )
            },
            {
              donor_currency: 'CAD',
              total_in_donor_currency: 3.0,
              converted_total_in_salary_currency:
                CurrencyRate.convert_on_date(
                  amount: 3.0,
                  date: 6.months.ago + 1.day,
                  from: 'CAD',
                  to: account_list.salary_currency
                )
            }
          ]
        },
        {
          month: 5.months.ago.beginning_of_month.to_date,
          totals_by_currency: []
        }
      ]
    end

    it 'returns a hash with monthly totals by currency' do
      expect(subject.donation_totals_by_month).to eq(expected_donation_amounts_by_month)
    end
  end
end
