require 'spec_helper'

describe Api::V1::CurrentAccountListsController do
  describe 'api' do
    let(:user) { create(:user_with_account) }
    let(:account_list) { user.account_lists.first }

    it 'gets current account list' do
      get :show, params: { access_token: user.access_token }
      expect(response).to be_success
      json = JSON.parse(response.body)['account_list']
      expect(json.keys).to eq(
        %w(id name created_at updated_at monthly_goal total_pledges designation_account_ids)
      )
      expect(json['id']).to eq(account_list.id)
      expect(json['name']).to eq(account_list.name)
      expect(json['monthly_goal']).to eq(account_list.monthly_goal)
      expect(json['total_pledges']).to eq(account_list.total_pledges)
      expect(json['designation_account_ids']).to eq(account_list.designation_accounts.map(&:id))
    end
  end
end
