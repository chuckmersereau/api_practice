require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Prayer Letters Account' do
  include_context :json_headers

  let(:resource_type) { 'prayer_letters_accounts' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:contact)        { create(:contact, account_list: account_list, send_newsletter: 'Both') }

  let(:resource_attributes) do
    %w(
      created_at
      token
      updated_at
      updated_in_db_at
    )
  end

  before do
    stub_request(:get, 'https://www.prayerletters.com/api/v1/contacts')
      .to_return(status: 200, body: '{"contacts":[ {"name": "John Doe", "file_as": "Doe, John",
        "external_id": "' + contact.id.to_s + '", "street": "123 Somewhere St", "city": "Fremont",
        "state": "CA", "postal_code": "94539"} ]}', headers: {})
    stub_request(:put, 'https://www.prayerletters.com/api/v1/contacts')
      .to_return(status: 200, body: '{"contacts":[ {"name": "John Doe", "file_as": "Doe, John",
        "external_id": "' + contact.id.to_s + '", "street": "123 Somewhere St", "city": "Fremont",
        "state": "CA", "postal_code": "94539"} ]}', headers: {})
  end

  context 'existent prayer letters account' do
    before do
      create(:prayer_letters_account, account_list: account_list)
    end

    context 'authorized user' do
      before { api_login(user) }

      get '/api/v2/account_lists/:account_list_id/prayer_letters_account' do
        parameter 'account_list_id', 'Account List ID', required: true

        with_options scope: [:data, :attributes] do
          response_field 'created_at',         'Created At',         'Type' => 'String'
          response_field 'token',              'Token',              'Type' => 'String'
          response_field 'updated_at',         'Updated At',         'Type' => 'String'
          response_field 'updated_in_db_at',   'Updated In Db At',   'Type' => 'String'
        end

        example 'Prayer Letters Account [GET]', document: :account_lists do
          explanation 'The Prayer Letters Account associated with the Account List'
          do_request
          check_resource
          expect(response_status).to eq 200
        end
      end

      delete '/api/v2/account_lists/:account_list_id/prayer_letters_account' do
        parameter 'account_list_id', 'Account List ID', required: true
        parameter 'id',              'ID', required: true

        example 'Prayer Letters Account [DELETE]', document: :account_lists do
          explanation 'Deletes the Prayer Letters Account associated with the Account List'
          do_request
          expect(response_status).to eq 204
        end
      end

      get '/api/v2/account_lists/:account_list_id/prayer_letters_account/sync' do
        parameter 'account_list_id', 'Account List ID', required: true

        example 'Prayer Letters Account [SYNC]', document: :account_lists do
          explanation "Synchronizes The Prayer Letters Account's subscribers with #{PrayerLettersAccount::SERVICE_URL}"
          do_request
          expect(response_status).to eq 200
        end
      end
    end
  end

  context 'non-existent prayer letters account' do
    post '/api/v2/account_lists/:account_list_id/prayer_letters_account' do
      before { api_login(user) }

      with_options scope: [:data, :attributes] do
        parameter 'oauth2_token', 'OAuth2 Token', required: true
      end

      let(:form_data) { build_data(oauth2_token: 'token') }

      example 'Prayer Letters Account [CREATE]', document: :account_lists do
        explanation 'Create a Prayer Letters Account associated with the Account List'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end
  end
end
