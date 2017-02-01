require 'spec_helper'

RSpec.describe Reports::MonthlyGivingGraph, type: :model do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:organization) { create(:organization) }
  let(:designation_account) do
    create(:designation_account, organization: organization)
  end
  let(:contact) { create(:contact, account_list: account_list) }
  let(:donor_account) { create(:donor_account, organization: organization) }
  let!(:donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      donation_date: Date.parse('2099-03-04'),
                      amount: '333')
  end
  let(:time_now) { Time.zone.parse('2099-06-22 12:34:56') }

  subject { Reports::MonthlyGivingGraph.new(account_list: account_list) }

  def mock_time
    allow(Time).to receive(:current).and_return(time_now)
    allow(Date).to receive(:today).and_return(time_now.to_date)
  end

  before do
    contact.donor_accounts << donor_account
    account_list.designation_accounts << designation_account
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(subject).to be_a(Reports::MonthlyGivingGraph)
      expect(subject.account_list).to eq(account_list)
    end
  end

  describe '#totals' do
    it { expect(subject.totals).to be_an Array }
    it { expect(subject.totals).not_to be_empty }

    it { expect(subject.totals.first[:currency]).to eq donation.currency }
    it do
      mock_time
      expect(subject.totals.first[:total_amount]).to eq donation.amount
    end
  end

  describe '#pledges' do
    it { expect(subject.pledges).to be_a Numeric }
    it { expect(subject.pledges).to eq contact.pledge_amount.to_i }
  end

  describe '#monthly_average' do
    it { expect(subject.monthly_average).to be_a Numeric }
    it do
      mock_time
      expect(subject.monthly_average).to eq 111
    end
  end

  describe '#months_to_dates' do
    it { expect(subject.months_to_dates).to be_an Array }
    it { expect(subject.months_to_dates).not_to be_empty }

    it { expect(subject.months_to_dates.first).to be_a Date }
    it do
      mock_time
      expect(subject.months_to_dates.first).to eq Date.parse('2099-03-01')
    end
  end

  describe '#salary_currency' do
    it { expect(subject.salary_currency).to be_a String }
    it { expect(subject.salary_currency).to eq organization.default_currency_code }
  end

  describe '#months_back' do
    it { expect(subject.months_back).to be_a Numeric }
    it do
      mock_time
      expect(subject.months_back).to eq 3
    end
  end
end
