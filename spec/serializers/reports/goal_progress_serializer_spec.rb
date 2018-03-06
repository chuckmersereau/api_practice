require 'rails_helper'

describe Reports::GoalProgressSerializer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:organization) { create(:organization) }
  let(:object) { Reports::GoalProgress.new(account_list: account_list) }

  subject { Reports::GoalProgressSerializer.new(object).as_json }

  before do
    account_list.salary_organization_id = organization.id
  end

  it 'serializes salary_organization_id' do
    expect(subject[:salary_organization_id]).to eq organization.id
  end
end
