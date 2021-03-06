require 'rails_helper'

RSpec.describe Reports::MonthlyGivingGraph, type: :model do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
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
                      amount: '1100')
  end
  let(:time_now) { Time.zone.parse('2099-06-22 12:34:56') }

  subject { described_class.new(account_list: account_list) }

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
    before { mock_time }

    it { expect(subject.totals).to be_an Array }
    it { expect(subject.totals).not_to be_empty }

    it { expect(subject.totals.first[:currency]).to eq donation.currency }
    it { expect(subject.totals.first[:total_amount]).to eq donation.amount }
  end

  describe '#pledges' do
    it { expect(subject.pledges).to be_a Numeric }
    it { expect(subject.pledges).to eq contact.pledge_amount.to_i }
  end

  describe '#monthly_average' do
    it { expect(subject.monthly_average).to be_a Numeric }
    it 'averages donations in the period requested' do
      mock_time
      expect(subject.monthly_average).to eq 100
    end
    it 'does not include donations made in the current month' do
      mock_time
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        donation_date: Date.parse('2099-06-04'),
                        amount: '100')
      expect(subject.monthly_average).to eq 100
    end
  end

  describe '#months_to_dates' do
    it { expect(subject.months_to_dates).to be_an Array }
    it { expect(subject.months_to_dates).not_to be_empty }

    it { expect(subject.months_to_dates.first).to be_a Date }
    it do
      mock_time
      expect(subject.months_to_dates.first).to eq Date.parse('2098-07-01')
    end
  end

  describe '#salary_currency' do
    it { expect(subject.salary_currency).to be_a String }
    it { expect(subject.salary_currency).to eq organization.default_currency_code }
  end

  describe '#display_currency' do
    it { expect(subject.display_currency).to be_a String }
    it { expect(subject.display_currency).to eq organization.default_currency_code }

    context 'display_currency set' do
      subject { Reports::MonthlyGivingGraph.new(account_list: account_list, display_currency: 'NZD') }
      it { expect(subject.display_currency).to eq 'NZD' }
    end
  end

  describe '#multi_currency' do
    it { expect(subject.multi_currency).to be false }
  end

  describe '#number_of_months_in_range' do
    it { expect(subject.send(:number_of_months_in_range)).to be_a Numeric }
    it 'excludes last month if that month is the current month' do
      mock_time
      expect(subject.send(:number_of_months_in_range)).to eq 11
    end
    context 'has filter_params where end date is not in current month' do
      before { mock_time }
      subject do
        described_class.new(account_list: account_list,
                            filter_params: {
                              donation_date: (Date.today - 14.months)...(Date.today - 2.months)
                            })
      end

      it 'includes last month' do
        mock_time
        expect(subject.send(:number_of_months_in_range)).to eq 13
      end
    end
  end
end
