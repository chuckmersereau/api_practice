require 'rails_helper'

RSpec.describe Reports::YearDonations, type: :model do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:year_donations) { Reports::YearDonations.new(account_list: account_list) }
  let!(:designation_account) { create(:designation_account) }
  let!(:donor_account) { create(:donor_account) }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:currency_rate) { CurrencyRate.create(exchanged_on: Date.current, code: 'EUR', rate: 0.5, source: 'test') }

  let!(:donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      amount: 2, currency: 'EUR',
                      donation_date: Date.current)
  end

  let!(:donation_last_year) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      amount: 2, currency: 'EUR',
                      donation_date: 13.months.ago.end_of_month - 1.day)
  end

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(year_donations).to be_a(Reports::YearDonations)
      expect(year_donations.account_list).to eq(account_list)
    end
  end

  describe '#donor_infos' do
    it 'returns donor infos' do
      expect(year_donations.donor_infos).to be_a(Array)
      expect(year_donations.donor_infos.size).to eq(1)
      expect(year_donations.donor_infos.first).to be_a(DonationReports::DonorInfo)
      expect(year_donations.donor_infos.first.contact_name).to eq(contact.name)
    end
  end

  describe '#donation_infos' do
    it 'returns donation infos' do
      expect(year_donations.donation_infos).to be_a(Array)
      expect(year_donations.donation_infos.size).to eq(1)
      expect(year_donations.donation_infos.first).to be_a(DonationReports::DonationInfo)
      expect(year_donations.donation_infos.first.amount).to eq(2)
    end

    it 'does not return donations made more than 12 months ago' do
      expect(donor_account.donations.size).to eq(2)
      expect(year_donations.donation_infos.size).to eq(1)
      expect(year_donations.donation_infos.first.donation_date).to eq(Date.current)
    end

    it 'converts amount' do
      expect(year_donations.donation_infos.first.converted_amount).to eq(4.0)
    end
  end
end
