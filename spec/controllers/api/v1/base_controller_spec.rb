require 'spec_helper'

describe Api::V1::BaseController do
  let(:user) { create(:user_with_account) }
  let(:second_account) { AccountList.create(name: 'Account 2') }

  describe '#current_account_list' do
    before do
      sign_in(user)
      user.account_lists << second_account
    end

    controller(Api::V1::BaseController) do
      def index
        session[:current_account_list_id] = current_account_list.id
        render nothing: true
      end
    end

    it 'uses the account_list_id param to set the current_account_list' do
      get :index, account_list_id: second_account.id
      expect(session[:current_account_list_id]).to eq(second_account.id)
    end
  end
end
