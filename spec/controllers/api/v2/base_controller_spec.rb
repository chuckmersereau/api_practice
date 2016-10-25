require 'spec_helper'

describe Api::V2::BaseController do
  let(:user) { create(:user_with_account) }
  let(:second_account) { AccountList.create(name: 'Account 2') }

  describe '#current_account_list' do
    before do
      user.account_lists << second_account
    end

    controller(Api::V2::BaseController) do
      def index
        session[:current_account_list_id] = current_account_list.id
        render nothing: true
      end
    end

    it 'doesnt allow signed in users to access the api' do
      get :index
      expect(session[:current_account_list_id]).to be_nil
    end

    it 'allows signed_in users with a valid token to access the api ' do
      sign_in(user)
      get :index
      expect(session[:current_account_list_id]).to eq(second_account.id)
    end
  end
end
