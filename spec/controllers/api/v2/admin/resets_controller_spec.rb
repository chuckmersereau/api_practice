require 'rails_helper'

RSpec.describe Api::V2::Admin::ResetsController do
  let(:admin_user) { create(:user, admin: true) }
  let(:reset_user) { create(:user_with_account) }
  let!(:key_account) { create(:key_account, person: reset_user) }
  let(:account_list) { reset_user.account_lists.order(:created_at).first }
  let(:given_resource_type) { :resets }
  let(:correct_attributes) do
    {
      resetted_user_email: key_account.email,
      reason: 'Resetting User Account',
      account_list_name: account_list.name
    }
  end
  let(:response_data) { JSON.parse(response.body)['data'] }
  let(:response_errors) { JSON.parse(response.body)['errors'] }

  include_context 'common_variables'

  context 'create' do
    it 'returns a 401 when someone is not logged in' do
      post :create, full_correct_attributes
      expect(response.status).to eq(401)
    end

    it 'returns a 403 when someone that is not an admin tries to create an organization' do
      api_login(create(:user))
      post :create, full_correct_attributes
      expect(response.status).to eq(403)
    end

    it 'returns a 400 when the account list name does not exist' do
      full_correct_attributes[:data][:attributes][:account_list_name] = 'random'
      api_login(admin_user)
      post :create, full_correct_attributes
      expect(response.status).to eq(400)
      expect(response_errors).to_not be_empty
    end

    it 'returns a 400 when the user email does not exist' do
      full_correct_attributes[:data][:attributes][:resetted_user_email] = 'random@email.com'
      api_login(admin_user)
      post :create, full_correct_attributes
      expect(response.status).to eq(400)
      expect(response_errors).to_not be_empty
    end

    it 'returns a 200 when an admin provides correct attributes' do
      api_login(admin_user)
      post :create, full_correct_attributes
      expect(response.status).to eq(200)
    end
  end
end
