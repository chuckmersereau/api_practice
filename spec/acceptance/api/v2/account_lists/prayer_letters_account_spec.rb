require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Prayer Letters Account' do
  let(:resource_type) { 'prayer-letters-accounts' }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list: account_list, send_newsletter: 'Both') }

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
      before do
        api_login(user)
      end
      get '/api/v2/account_lists/:account_list_id/prayer-letters-account' do
        parameter 'account-list-id', 'Account List ID', required: true
        with_options scope: [:data, :attributes] do
          response_field :token,                    'Token', 'Type' => 'String'
          response_field 'created-at',              'Created At', 'Type' => 'Date'
          response_field 'updated-at',              'Updated At', 'Type' => 'Date'
        end
        example_request 'get prayer letters account' do
          check_resource
          expect(resource_object.keys).to eq %w(token created-at updated-at)
          expect(status).to eq 200
        end
      end
      delete '/api/v2/account_lists/:account_list_id/prayer-letters-account' do
        parameter 'account-list-id',              'Account List ID', required: true
        parameter 'id',                           'ID', required: true
        example_request 'delete prayer letters account' do
          expect(status).to eq 200
        end
      end
      get '/api/v2/account_lists/:account_list_id/prayer-letters-account/sync' do
        parameter 'account-list-id',              'Account List ID', required: true
        response_field :data,                     'Data', 'Type' => 'Array'
        example_request 'sync prayer letters account' do
          expect(status).to eq 200
        end
      end
    end
  end

  context 'non-existent prayer letters account' do
    post '/api/v2/account_lists/:account_list_id/prayer-letters-account' do
      before do
        api_login(user)
      end
      with_options scope: [:data, :attributes] do
        parameter 'oauth2-token',                 'OAuth2 Token', required: true
        parameter 'valid-token',                  'OAuth2 Token', required: true
      end
      let(:form_data) { build_data('oauth2-token': 'token', 'valid-token': true) }
      example 'create a prayer letters account' do
        do_request data: form_data
        expect(status).to eq 200
      end
    end
  end
end
