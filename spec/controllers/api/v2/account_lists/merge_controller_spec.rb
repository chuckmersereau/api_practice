require 'spec_helper'

describe Api::V2::AccountLists::MergeController, type: :controller do
  let(:resource_type) { 'merge' }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:account_list2) { create(:account_list) }
  let(:account_list_id) { account_list.id }
  let(:account_list2_id) { account_list2.id }

  context 'authorized user' do
    before do
      account_list2.users << user
      api_login(user)
    end

    describe '#create' do
      it 'makes a merge' do
        data = { attributes: { id: account_list2_id } }
        post :create, account_list_id: account_list_id, data: data
        expect(response.status).to eq 200
      end

      it 'does not make a merge' do
        data = { attributes: { id: account_list_id } }
        post :create, account_list_id: account_list_id, data: data
        expect(response.status).to eq 400
      end
    end
  end

  context 'unauthorized user' do
    describe '#create' do
      it 'does not make a merge' do
        post :create, account_list_id: account_list_id
        expect(response.status).to eq 401
      end
    end
  end
end
