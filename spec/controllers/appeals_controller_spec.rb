require 'spec_helper'

RSpec.describe AppealsController, type: :controller do
  describe 'GET #show' do
    before(:each) do
      @user = FactoryGirl.create(:user_with_account)
      sign_in(:user, @user)
    end

    it 'returns http success' do
      appeal = create(:appeal, account_list: @user.account_lists.first)
      get :show, id: appeal.id
      expect(response).to have_http_status(:success)
    end
  end
end
