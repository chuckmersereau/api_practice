require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Impersonation' do
  include_context :json_headers

  let(:admin_user) { create(:user_with_account, admin: true) }
  let(:impersonated_user) { create(:user) }
  let(:request_type) { 'impersonation' }
  let(:form_data) { build_data(reason: 'Reason', user: impersonated_user.uuid) }

  context 'authorized user' do
    before { api_login(admin_user) }

    post '/api/v2/admin/impersonation' do
      with_options scope: [:data, :attributes] do
        parameter :reason, 'The reason for the impersonation'
        parameter :user,   'The User Name, ID or Key/Relay Email of the user to impersonate'
      end

      example 'Impersonation', document: false do
        explanation 'This endpoint allows an admin to impersonate any user by receiving a jwt that can ' \
                    'be used to access any resources on the API on behalf of the impersonated user.'

        do_request data: form_data

        expect(response_status).to eq 200
        expect(json_response['data']['attributes']['json_web_token']).to be_present
      end
    end
  end
end
