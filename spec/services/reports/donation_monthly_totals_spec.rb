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
                      tendered_amount: 3, tendered_currency: 'CAD',
                      donation_date: 6.months.ago + 1.day)
  end

  let!(:eur_donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      tendered_amount: 2, tendered_currency: 'EUR',
                      donation_date: 6.months.ago + 2.days)
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
              converted_total_in_salary_currency: 9.99
            },
            {
              donor_currency: 'CAD',
              total_in_donor_currency: 3.0,
              converted_total_in_salary_currency: 9.99
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
