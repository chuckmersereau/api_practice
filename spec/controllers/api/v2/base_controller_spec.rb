require 'spec_helper'

describe Api::V2::BaseController do
  let(:user) { create(:user_with_account) }
  let(:second_account) { AccountList.create(name: 'Account 2') }
  let(:token) { double :acceptable? => true }

  describe '#current_account_list' do
    before do
      user.account_lists << second_account
    end

    controller(Api::V2::BaseController) do
      def index
        render nothing: true
      end
    end

    it 'doesnt allow signed in users to access the api' do
      get :index, format: :json
      expect(response.status).to eq(401)
    end

    it 'allows signed_in users with a valid token to access the api ' do
      controller.stub(:doorkeeper_token) { token }
      get :index, format: :json
      expect(response.status).to eq(200)
    end
  end
end
