require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists' do
  let(:resource_type) { 'account-lists' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:id) { account_list.id }
  let(:new_account_list) { build(:account_list).attributes }
  let(:form_data) { build_data(new_account_list) }
  let(:expected_attribute_keys) do
    %w(created-at
       default-organization-id
       monthly-goal
       name
       total-pledges
       updated-at)
  end

  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account-lists' do
      response_field :data, 'Data', 'Type' => 'Array[Object]'
      example_request 'list account lists of current user' do
        check_collection_resource(1)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/account-lists/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'default-organization-id', 'Organization ID', 'Type' => 'Number'
        response_field 'monthly-goal',            'Monthly Goal', 'Type' => 'Number'
        response_field 'name',                    'Account Name', 'Type' => 'String'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
      end
      example_request 'get account list' do
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['name']).to eq account_list.name
        expect(status).to eq 200
      end
    end
    put '/api/v2/account-lists/:id' do
      parameter 'id', 'ID of the Account List', required: true
      with_options scope: [:data, :attributes] do
        parameter 'name',                          'Account Name', required: true
        parameter 'settings',                      'Settings'
      end
      example 'update account list' do
        do_request data: form_data
        expect(resource_object['name']).to eq new_account_list['name']
        expect(status).to eq 200
      end
    end
  end
end
