require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  include_context :json_headers

  let(:resource_type) { 'users' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)    { user.account_lists.first }
  let(:account_list_id)  { account_list.id }

  let!(:users)           { create_list(:user, 2) }
  let(:user2)            { users.last }
  let(:id)               { user2.id }
  let(:original_user_id) { user.id }

  let(:expected_attribute_keys) do
    %w(
      created_at
      first_name
      last_name
      master_person_id
      preferences
      updated_at
    )
  end

  before do
    account_list.users += users
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/users' do
      example 'User [LIST]', document: :account_lists do
        do_request
        explanation 'Users of selected account list'

        check_collection_resource(3, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/users/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'first_name',       'First name',       'Type' => 'String'
        response_field 'last_name',        'Last name',        'Type' => 'String'
        response_field 'master_person_id', 'Master Person ID', 'Type' => 'Number'
        response_field 'preferences',      'Preferences',      'Type' => 'Object'
      end

      example 'User [GET]', document: :account_lists do
        do_request
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['first_name']).to eq user2.first_name
        expect(resource_object['last_name']).to eq user2.last_name
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/users/:id' do
      example 'User [DELETE]', document: :account_lists do
        do_request
        expect(response_status).to eq 200
      end
    end
  end
end
