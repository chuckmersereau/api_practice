require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Designation Accounts' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'designation_accounts' }
  let(:user)          { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let(:designation_account) { create(:designation_account) }
  let(:id)                  { designation_account.id }

  let(:expected_attribute_keys) do
    %w(
      balance
      created_at
      designation_number
      name
      updated_at
    )
  end

  context 'authorized user' do
    before do
      account_list.designation_accounts << designation_account
      api_login(user)
    end

    get '/api/v2/account_lists/:account_list_id/designation_accounts' do
      parameter 'account_list_id', 'Account List ID', required: true
      response_field 'data',       'Data', 'Type' => 'Array[Object]'

      example 'Designation Account [LIST]', document: :account_lists do
        do_request
        check_collection_resource(1)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/designation_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'balance',            'Balance',            'Type' => 'Number'
        response_field 'created_at',         'Created At',         'Type' => 'String'
        response_field 'designation_number', 'Designation Number', 'Type' => 'String'
        response_field 'name',               'Name',               'Type' => 'String'
        response_field 'updated_at',         'Updated At',         'Type' => 'String'
      end

      example 'Designation Account [GET]', document: :account_lists do
        do_request
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['designation_number']).to eq designation_account.designation_number
        expect(response_status).to eq 200
      end
    end
  end
end
