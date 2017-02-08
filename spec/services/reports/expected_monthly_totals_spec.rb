require 'rails_helper'

RSpec.describe Reports::ExpectedMonthlyTotals, type: :model do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:expected_monthly_totals) { Reports::ExpectedMonthlyTotals.new(account_list: account_list) }
  let!(:designation_account) { create(:designation_account) }
  let!(:donor_account) { create(:donor_account) }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:contact_with_pledge) { create(:contact, account_list: account_list, pledge_amount: 50) }
  let!(:currency_rate) { CurrencyRate.create(exchanged_on: Date.current, code: 'EUR', rate: 0.5, source: 'test') }

  let!(:donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      tendered_amount: 2, tendered_currency: 'EUR',
                      donation_date: Date.current)
  end

  let!(:donation_last_year) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      tendered_amount: 2, tendered_currency: 'EUR',
                      donation_date: 13.months.ago.end_of_month - 1.day)
  end

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(expected_monthly_totals).to be_a(Reports::ExpectedMonthlyTotals)
      expect(expected_monthly_totals.account_list).to eq(account_list)
    end
  end

  describe '#expected_donations' do
    it 'returns donations infos' do
      expect(expected_monthly_totals.expected_donations).to be_a(Array)
      expect(expected_monthly_totals.expected_donations.size).to eq(2)
      expect(expected_monthly_totals.expected_donations.first[:contact_name]).to eq(contact.name)
    end

    it 'returns received donations' do
      expect(expected_monthly_totals.expected_donations.detect { |hash| hash[:type] == 'received' }).to be_present
    end

    it 'returns possible donations' do
      expect(expected_monthly_totals.expected_donations.detect { |hash| hash[:type] == 'unlikely' }).to be_present
    end
  end

  describe '#total_currency' do
    it 'returns total_currency' do
      expect(expected_monthly_totals.total_currency).to eq('USD')
    end
  end

  describe '#total_currency_symbol' do
    it 'returns total_currency_symbol' do
      expect(expected_monthly_totals.total_currency_symbol).to eq('$')
    end
  end
end
