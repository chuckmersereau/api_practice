require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Google Accounts' do
  include_context :json_headers

  let(:resource_type) { 'person_google_accounts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:google_account) { create(:google_account, person: user) }
  let(:id)              { google_account.id }

  let(:new_google_account) { build(:google_account, person: user).attributes }
  let(:form_data)          { build_data(new_google_account) }

  let(:resource_associations) do
    %w(
      person
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/user/google_accounts' do
      example 'Google Account [LIST]', document: :user do
        do_request
        explanation 'List of Google Accounts associated to current_user'
        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/user/google_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'expires_at',    'Expires At',    'Type' => 'String'
        response_field 'person_id',     'Person Id',     'Type' => 'Number'
        response_field 'refresh_token', 'Refresh Token', 'Type' => 'String'
        response_field 'remote_id',     'Remote Id',     'Type' => 'Number'
        response_field 'token',         'Token',         'Type' => 'String'
      end

      example 'Google Account [GET]', document: :user do
        explanation 'The current_user\'s Google Account with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/user/google_accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'expires_at',     'Expires At'
        parameter 'person_id',      'Person Id', required: true
        parameter 'refresh_token',  'Refresh Token'
        parameter 'remote_id',      'Remote Id', required: true
        parameter 'token',          'Token'
      end

      example 'Google Account [CREATE]', document: :user do
        explanation 'Create a Google Account associated with the current_user'
        do_request data: form_data
        expect(resource_object['username']).to eq new_google_account['username']
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/user/google_accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'expires_at',     'Expires At'
        parameter 'person_id',      'Person Id', required: true
        parameter 'refresh_token',  'Refresh Token'
        parameter 'remote_id',      'Remote Id', required: true
        parameter 'token',          'Token'
      end

      example 'Google Account [UPDATE]', document: :user do
        explanation 'Update the current_user\'s Google Account with the given ID'
        do_request data: form_data
        expect(resource_object['username']).to eq new_google_account['username']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/user/google_accounts/:id' do
      example 'Google Account [DEKETE]', document: :user do
        explanation 'Delete the current_user\'s Google Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
