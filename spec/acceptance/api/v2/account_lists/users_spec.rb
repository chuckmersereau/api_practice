require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  let(:resource_type) { 'users' }
  let!(:user) { create(:user_with_account) }
  let!(:users) { create_list(:user, 2) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:user2) { users.last }
  let(:id) { user2.id }
  let(:original_user_id) { user.id }
  let(:expected_attribute_keys) { %w(created-at updated-at first-name last-name master-person-id preferences) }
  before do
    account_list.users += users
  end
  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account-lists/:account_list_id/users' do
      example_request 'list users of account list' do
        explanation 'Users of selected account list'
        check_collection_resource(3, ['relationships'])
        expect(resource_object.keys).to match expected_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/account-lists/:account_list_id/users/:id' do
      example_request 'get user' do
        check_resource(['relationships'])
        expect(resource_object.keys).to match expected_attribute_keys
        expect(resource_object['first-name']).to eq user2.first_name
        expect(resource_object['last-name']).to eq user2.last_name
        expect(status).to eq 200
      end
    end
    delete '/api/v2/account-lists/:account_list_id/users/:id' do
      example_request 'delete user' do
        expect(status).to eq 200
      end
    end
  end
end
