require 'rails_helper'

RSpec.describe Api::V2::Admin::OrganizationsController do
  let(:admin_user) { create(:user, admin: true) }
  let(:given_resource_type) { :organizations }
  let(:correct_attributes) do
    {
      name: 'Cru (Offline)',
      org_help_url: 'https://cru.org',
      country: 'United States'
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

    it 'returns a 400 when the name is not set' do
      full_correct_attributes[:data][:attributes][:name] = ''
      api_login(admin_user)
      post :create, full_correct_attributes
      expect(response.status).to eq(400)
      expect(response_errors).to_not be_empty
    end

    it 'returns a 201 when an admin provides correct attributes' do
      api_login(admin_user)
      post :create, full_correct_attributes
      expect(response.status).to eq(201)
    end

    it 'creates an organization' do
      api_login(admin_user)
      expect { post :create, full_correct_attributes }.to change { Organization.count }.from(0).to(1)
      organization = Organization.first
      expect(organization.query_ini_url).to match '.{8}\.example\.com'
      expect(organization.api_class).to eq 'OfflineOrg'
      expect(organization.addresses_url).to eq 'example.com'
    end
  end
end
