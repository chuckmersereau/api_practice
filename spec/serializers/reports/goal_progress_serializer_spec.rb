require 'spec_helper'

describe Reports::GoalProgressSerializer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:object) { Reports::GoalProgress.new(account_list: account_list) }

  subject { Reports::GoalProgressSerializer.new(object).as_json }

  it { should include :in_hand_percent }
  it { should include :monthly_goal }
  it { should include :pledged_percent }
  it { should include :received_pledges }
  it { should include :salary_balance }
  it { should include :salary_currency_or_default }
  it { should include :salary_organization_id }
  it { should include :total_pledges }

  it 'serializes salary_organization_id' do
    expect(subject[:salary_organization_id]).to eq Organization.find(account_list.salary_organization_id).uuid
  end
end
