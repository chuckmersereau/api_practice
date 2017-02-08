require 'rails_helper'

RSpec.describe Api::V2::User::AuthenticationsController, type: :controller do
  let!(:user) { create(:user) }

  describe '#create' do
    before do
      allow(User).to receive(:from_access_token).with('wrong_token').and_return(nil)
      allow(User).to receive(:from_access_token).with('right_token').and_return(user)
    end

    it 'doesnt issue a token to users with invalid access token' do
      post :create, access_token: 'wrong_token'
      expect(response.status).to eq(401)
      expect(response.body).to include('Unauthorized')
    end

    it 'does issue a token to users with valid access token' do
      post :create, access_token: 'right_token'
      expect(response.status).to eq(201)
      expect(response.body).to include('token')
    end
  end
end
