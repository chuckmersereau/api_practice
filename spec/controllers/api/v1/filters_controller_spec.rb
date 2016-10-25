require 'spec_helper'

describe Api::V1::FiltersController do
  let!(:user) { create(:user_with_account) }
  let!(:contact) { create(:contact, account_list: user.account_lists.first) }

  describe 'get index' do
    it 'responds success' do
      get :index, access_token: user.access_token
      expect(response).to be_success
    end
    it 'returns contact and task filters' do
      get :index, access_token: user.access_token
      json = JSON.parse(response.body)
      expect(json['contact_filters'].length).to eq(29)
      expect(json['task_filters'].length).to eq(2)
    end
  end
end
