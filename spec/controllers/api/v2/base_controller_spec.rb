require 'spec_helper'

describe Api::V2::BaseController do
  let(:user) { create(:user_with_account) }

  describe '#current_account_list' do
    controller(Api::V2::BaseController) do
      def index
        session[:current_account_list] = current_account_list
        render nothing: true
      end
    end

    it 'doesnt allow not signed in users to access the api' do
      get :index, format: :json
      expect(response.status).to eq(401)
    end

    it 'allows signed_in users with a valid token to access the api' do
      api_login(user)
      get :index, format: :json
      expect(response.status).to eq(200)
      expect(session[:current_account_list]).to eq(user.account_lists.first)
    end
  end
end
