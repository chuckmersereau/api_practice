require 'rails_helper'

RSpec.describe Reports::GoalProgress, type: :model do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:report) { Reports::GoalProgress.new(account_list: account_list) }
  let!(:designation_account) { create(:designation_account, organization_id: account_list.salary_organization_id, balance: '9.99') }

  before do
    account_list.designation_accounts << designation_account
    account_list.monthly_goal = 1000.00
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(report).to be_a(Reports::GoalProgress)
      expect(report.account_list).to eq account_list
    end
  end

  describe '#salary_balance' do
    it 'returns the total salary balance' do
      account_list.designation_accounts << create(:designation_account, organization_id: account_list.salary_organization_id, balance: '0.01')
      expect(report.salary_balance).to eq 10.00
    end

    it 'converts balance to salary currency' do
      create(:currency_rate, code: 'USD', rate: 1)
      create(:currency_rate, code: 'KRW', rate: 10)
      Organization.find(account_list.salary_organization_id).update(default_currency_code: 'USD')
      expect(report.salary_balance).to eq 9.99
      Organization.find(account_list.salary_organization_id).update(default_currency_code: 'KRW')
      expect(report.salary_balance).to eq 0.999
    end
  end

  describe 'delegation' do
    it 'delegates methods to account list' do
      expect(report.in_hand_percent).to eq account_list.in_hand_percent
      expect(report.monthly_goal).to eq account_list.monthly_goal
      expect(report.pledged_percent).to eq account_list.pledged_percent
      expect(report.received_pledges).to eq account_list.received_pledges
      expect(report.salary_currency_or_default).to eq account_list.salary_currency_or_default
      expect(report.salary_organization_id).to eq account_list.salary_organization_id
      expect(report.total_pledges).to eq account_list.total_pledges
    end
  end
end
