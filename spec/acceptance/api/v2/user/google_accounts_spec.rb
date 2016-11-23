require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Google Accounts' do
  let(:resource_type) { 'person-google-accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:google_account) { create(:google_account, person: user) }
  let(:id) { google_account.id }
  let(:new_google_account) { build(:google_account, person: user).attributes }
  let(:form_data) { build_data(new_google_account) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/user/google-accounts' do
      example_request 'get organization accounts' do
        explanation 'List of Organization Accounts associated to current_user'
        check_collection_resource(1)
        expect(status).to eq 200
      end
    end

    get '/api/v2/user/google-accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field :token, 'Token', 'Type' => 'String'
        response_field :refresh_token, 'Refresh Token', 'Type' => 'String'
        response_field :expires_at, 'Expires At', 'Type' => 'Datetime'
        response_field :remote_id, 'Remote Id', 'Type' => 'Integer'
        response_field :person_id, 'Person Id', 'Type' => 'Integer'
      end

      example_request 'get organization account' do
        check_resource
        expect(status).to eq 200
      end
    end

    post '/api/v2/user/google-accounts' do
      with_options scope: [:data, :attributes] do
        parameter :token, 'Token'
        parameter :refresh_token, 'Refresh Token'
        parameter :expires_at, 'Expires At'
        parameter :remote_id, 'Remote Id', required: true
        parameter :person_id, 'Person Id', required: true
      end

      example 'create organization account' do
        do_request data: form_data
        expect(resource_object['username']).to eq new_google_account['username']
        expect(status).to eq 200
      end
    end

    put '/api/v2/user/google-accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter :token, 'Token'
        parameter :refresh_token, 'Refresh Token'
        parameter :expires_at, 'Expires At'
        parameter :remote_id, 'Remote Id', required: true
        parameter :person_id, 'Person Id', required: true
      end

      example 'update notification' do
        do_request data: form_data
        expect(resource_object['username']).to eq new_google_account['username']
        expect(status).to eq 200
      end
    end

    delete '/api/v2/user/google-accounts/:id' do
      example_request 'delete notification' do
        expect(status).to eq 200
      end
    end
  end
end
