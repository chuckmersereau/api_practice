require 'spec_helper'

RSpec.describe Api::V2::Constants::NotificationsController, type: :controller do
  let(:user) { create(:user_with_account) }

  describe '#index' do
    it 'shows resources to users that are signed in' do
      api_login(user)
      get :index
      expect(response.status).to eq(200)
    end

    it 'does not shows resources to users that are not signed in' do
      get :index
      expect(response.status).to eq(401)
    end
  end
end
