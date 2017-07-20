require 'rails_helper'

RSpec.describe Api::V2::Admin::ImpersonationController do
  let(:user) { create(:user_with_account, admin: true) }
  let(:user_to_impersonate) { create(:user) }
  let(:account_list) { user.account_lists.first }
  let(:given_resource_type) { :impersonation }
  let(:correct_attributes) { { reason: 'Reason', user: user_to_impersonate.uuid } }
  let(:response_data) { JSON.parse(response.body)['data'] }

  include_context 'common_variables'

  context 'create' do
    it 'returns a 401 when someone is not logged in' do
      post :create, full_correct_attributes
      expect(response.status).to eq(401)
    end

    it 'returns a 403 when someone that is not an admin tries to impersonate' do
      api_login(create(:user))
      post :create, full_correct_attributes
      expect(response.status).to eq(403)
    end

    it 'returns a 404 when the user uuid does not exist' do
      full_correct_attributes[:data][:attributes][:user] = SecureRandom.uuid
      api_login(user)
      post :create, full_correct_attributes
      expect(response.status).to eq(404)
    end

    it 'returns a 200 when someone an admin is logged in' do
      travel_to(Time.now)
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { Admin::ImpersonationLog.count }.by(1)
      expect(response.status).to eq(200)
      expect(response_data['attributes']['json_web_token']).to eq(
        JsonWebToken.encode(
          user_uuid: user_to_impersonate.uuid,
          exp: 20.minutes.from_now.utc.to_i
        )
      )
      travel_back
    end
  end
end
