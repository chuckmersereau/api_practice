require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'User > Google Accounts' do
  include_context :json_headers
  documentation_scope = :user_api_google_accounts

  let!(:user)         { create(:user_with_full_account) }
  let(:resource_type) { 'google_accounts' }

  let!(:google_account) { create(:google_account, person: user) }
  let(:id)              { google_account.uuid }

  let(:new_google_account) do
    attributes_for(:google_account)
      .merge(updated_in_db_at: google_account.updated_at)
      .tap { |attrs| attrs.delete(:person_id) }
  end

  let(:relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: user.uuid
        }
      }
    }
  end

  let(:form_data) { build_data(new_google_account, relationships: relationships) }

  let(:resource_attributes) do
    %w(
      created_at
      email
      expires_at
      last_download
      last_email_sync
      primary
      refresh_token
      remote_id
      token
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/user/google_accounts' do
      example 'Google Account [LIST]', document: documentation_scope do
        do_request
        explanation 'List of Google Accounts associated to current_user'
        check_collection_resource(1)
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/user/google_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',       'Created At',       type: 'String'
        response_field 'expires_at',       'Expires At',       type: 'String'
        response_field 'last_download',    'Last Download',    type: 'String'
        response_field 'last_email_sync',  'Last Email Sync',  type: 'String'
        response_field 'primary',          'Primary',          type: 'Boolean'
        response_field 'refresh_token',    'Refresh Token',    type: 'String'
        response_field 'remote_id',        'Remote Id',        type: 'Number'
        response_field 'token',            'Token',            type: 'String'
        response_field 'updated_at',       'Updated At',       type: 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', type: 'String'
      end

      example 'Google Account [GET]', document: documentation_scope do
        explanation 'The current_user\'s Google Account with the given ID'
        do_request
        check_resource
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

      example 'Google Account [CREATE]', document: documentation_scope do
        explanation 'Create a Google Account associated with the current_user'
        do_request data: form_data
        expect(resource_object['token']).to eq new_google_account[:token]
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

      example 'Google Account [UPDATE]', document: documentation_scope do
        explanation 'Update the current_user\'s Google Account with the given ID'
        do_request data: form_data
        expect(resource_object['token']).to eq new_google_account[:token]
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/user/google_accounts/:id' do
      example 'Google Account [DELETE]', document: documentation_scope do
        explanation 'Delete the current_user\'s Google Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
