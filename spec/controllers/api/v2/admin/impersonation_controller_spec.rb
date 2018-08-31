require 'rails_helper'

RSpec.describe Api::V2::Admin::ImpersonationController do
  let!(:user) { create(:user_with_account, admin: true) }
  let(:email) { 'bob@burgers.com' }
  let!(:user_to_impersonate) { create(:user, email: email) }
  let!(:key_account) { create(:key_account, user: user_to_impersonate, email: email) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:given_resource_type) { :impersonation }
  let(:correct_attributes) { { reason: 'Reason' } }
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

    it 'returns a 404 when the user id does not exist' do
      full_correct_attributes[:data][:attributes][:user] = SecureRandom.uuid
      api_login(user)
      post :create, full_correct_attributes
      expect(response.status).to eq(404)
    end

    it 'returns a 404 when the user email does not exist' do
      full_correct_attributes[:data][:attributes][:user] = 'random@email.com'
      api_login(user)
      post :create, full_correct_attributes
      expect(response.status).to eq(404)
    end

    it 'returns a 200 when an admin is logged in and searches the user by ID' do
      expect_admin_user_to_be_able_to_impersonate_with_id(user_to_impersonate.id)
    end

    it 'returns a 200 when an admin is logged in and searches the user by email' do
      expect_admin_user_to_be_able_to_impersonate_with_id(email)
    end

    def expect_admin_user_to_be_able_to_impersonate_with_id(user_key)
      travel_to(Time.now.getlocal)
      api_login(user)
      expect do
        full_correct_attributes[:data][:attributes][:user] = user_key
        post :create, full_correct_attributes
      end.to change { Admin::ImpersonationLog.count }.by(1)
      expect(response.status).to eq(200)
      expect(response_data['attributes']['json_web_token']).to eq(
        JsonWebToken.encode(
          user_id: user_to_impersonate.id,
          exp: 1.hour.from_now.utc.to_i
        )
      )
      travel_back
    end
  end
end
