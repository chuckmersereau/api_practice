require 'rails_helper'

RSpec.describe Reports::MonthlyLossesGraph, type: :model do
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
                      amount: '1200')
  end
  let(:today) { Time.zone.parse('2099-06-22 12:34:56') }

  subject do
    Reports::MonthlyLossesGraph.new(account_list: account_list, months: 3,
                                    today: today)
  end

  before do
    contact.donor_accounts << donor_account
    account_list.designation_accounts << designation_account
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(subject).to be_a(Reports::MonthlyLossesGraph)
      expect(subject.account_list).to eq(account_list)
    end
  end

  describe '#losses with no balances' do
    it { expect(subject.losses.size).to eq 3 }
    it { expect(subject.losses).to eq Array.new(3, 0.0) }
  end

  describe '#losses' do
    before do
      create_balance balance: 100, created_at: today - 1.month
      create_balance balance: 50, created_at: today - 5.days
    end

    it { expect(subject.losses.size).to eq 3 }

    it { expect(subject.losses).to eq [0.00, -100.00, 50.00] }
  end

  describe '#month_names' do
    it { expect(subject.month_names.size).to eq 3 }
    it { expect(subject.month_names).to eq ['Apr 2099', 'May 2099', 'Jun 2099'] }
  end

  describe '#losses_with_month_names with no balances' do
    it { expect(subject.losses.size).to eq 3 }
    it { expect(subject.losses).to eq Array.new(3, 0.0) }
  end

  describe '#losses_with_month_names' do
    before do
      create_balance balance: 100, created_at: today - 1.month
      create_balance balance: 50, created_at: today - 5.days
    end

    it { expect(subject.losses_with_month_names.size).to eq 3 }

    it do
      expect(subject.losses_with_month_names).to eq 'Apr 2099' => 0.00,
                                                    'May 2099' => -100.00,
                                                    'Jun 2099' => 50.00
    end
  end

  private

  def create_balance(args = {})
    create :balance, args.merge(resource: designation_account)
  end
end
