require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  let(:resource_type) { 'users' }

  let!(:user)            { create(:user_with_account) }
  let!(:users)           { create_list(:user, 2) }
  let!(:account_list)    { user.account_lists.first }
  let(:account_list_id)  { account_list.id }
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
    before do
      api_login(user)
    end

    get '/api/v2/account_lists/:account_list_id/users' do
      example_request 'list users of account list' do
        explanation 'Users of selected account list'

        check_collection_resource(3, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/users/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'first-name',              'First name', 'Type' => 'String'
        response_field 'last-name',               'Last name', 'Type' => 'String'
        response_field 'master-person-id',        'Master Person ID', 'Type' => 'Number'
        response_field 'preferences',             'Preferences', 'Type' => 'Object'
      end

      example_request 'get user' do
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['first_name']).to eq user2.first_name
        expect(resource_object['last_name']).to eq user2.last_name
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/users/:id' do
      example_request 'delete user' do
        expect(response_status).to eq 200
      end
    end
  end
end
