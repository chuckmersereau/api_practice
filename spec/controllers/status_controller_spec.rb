require 'spec_helper'

RSpec.describe StatusController, type: :controller do
  before(:each) do
    sign_in(:user, FactoryGirl.create(:user_with_account))
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index
      expect(response).to be_success
    end
  end
end
