require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Users' do
  include_context :json_headers
  documentation_scope = :account_lists_api_users

  let(:resource_type) { 'users' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)    { user.account_lists.first }
  let(:account_list_id)  { account_list.uuid }

  let!(:users)           { create_list(:user, 2) }
  let(:user2)            { users.last }
  let(:id)               { user2.uuid }
  let(:original_user_id) { user.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      first_name
      last_name
      preferences
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_lists
      email_addresses
      master_person
    )
  end

  before do
    account_list.users += users
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/users' do
      example 'User [LIST]', document: documentation_scope do
        explanation 'List of Users associated to the Account List'
        do_request

        check_collection_resource(3, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/users/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',       'Created At',       'Type' => 'String'
        response_field 'first_name',       'First name',       'Type' => 'String'
        response_field 'last_name',        'Last name',        'Type' => 'String'
        response_field 'master_person_id', 'Master Person ID', 'Type' => 'Number'
        response_field 'preferences',      'Preferences',      'Type' => 'Object'
        response_field 'updated_at',       'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', 'Type' => 'String'
      end

      example 'User [GET]', document: documentation_scope do
        explanation 'The Account List User with the given ID'
        do_request
        check_resource(['relationships'])
        expect(resource_object['first_name']).to eq user2.first_name
        expect(resource_object['last_name']).to eq user2.last_name
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/users/:id' do
      example 'User [DELETE]', document: documentation_scope do
        explanation 'Destroy the Account List User with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
