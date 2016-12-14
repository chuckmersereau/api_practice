require 'spec_helper'

describe Api::V2::AccountLists::UsersController, type: :controller do
  let(:factory_type) { :user }
  let!(:user) { create(:user_with_account) }
  let!(:users) { create_list(:user, 2) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let(:user2) { users.last }
  let(:id) { user2.uuid }
  let(:original_user_id) { user.uuid }

  before do
    account_list.users += users
  end

  let(:resource) { user2 }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:user) }

  include_examples 'index_examples'

  include_examples 'show_examples'

  context 'authorized user' do
    before do
      api_login(user)
    end

    describe '#destroy' do
      it 'deletes an user' do
        delete :destroy, account_list_id: account_list_id, id: id
        expect(response.status).to eq 204
      end

      it 'does not deletes himself' do
        delete :destroy, account_list_id: account_list_id, id: original_user_id
        expect(response.status).to eq 403
      end
    end
  end
end
