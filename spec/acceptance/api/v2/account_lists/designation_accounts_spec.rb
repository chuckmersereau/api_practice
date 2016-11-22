require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Designation Accounts' do
  let(:resource_type) { 'designation-accounts' }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:designation_account) { create(:designation_account) }
  let(:id) { designation_account.id }
  let(:expected_attribute_keys) { %w(designation-number balance name created-at updated-at) }

  context 'authorized user' do
    before do
      account_list.designation_accounts << designation_account
      api_login(user)
    end
    get '/api/v2/account_lists/:account_list_id/designation-accounts' do
      parameter 'account-list-id',              'Account List ID', required: true
      response_field :data,                     'Data', 'Type' => 'Array[Object]'
      example_request 'list designation accounts of account list' do
        check_collection_resource(1)
        expect(resource_object.keys).to eq expected_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/account_lists/:account_list_id/designation-accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'designation-number',      'Designation Number', 'Type' => 'String'
        response_field :balance,                  'Balance', 'Type' => 'String'
        response_field :name,                     'Name', 'Type' => 'String'
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
      end
      example_request 'get designation account' do
        check_resource
        expect(resource_object.keys).to eq expected_attribute_keys
        expect(resource_object['designation-number']).to eq designation_account.designation_number
        expect(status).to eq 200
      end
    end
  end
end
