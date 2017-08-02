require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Organizations' do
  include_context :json_headers

  let(:admin_user) { create(:user_with_account, admin: true) }
  let(:request_type) { 'organizations' }
  let(:form_data) { build_data(name: 'Cru (Offline)', org_help_url: 'https://cru.org', country: 'United States') }

  context 'authorized user' do
    before { api_login(admin_user) }

    post '/api/v2/admin/organizations' do
      with_options scope: [:data, :attributes] do
        parameter :name,         'The name of the new organization'
        parameter :org_help_url, 'The url of the organization'
        parameter :country,      'The default country that account lists associated with this organization will be set to'
      end

      example 'Organization [CREATE]', document: false do
        explanation 'This endpoint allows an admin to create an organization.'
        do_request data: form_data

        expect(response_status).to eq 201
        expect(json_response['data']['attributes']['name']).to eq 'Cru (Offline)'
      end
    end
  end
end
