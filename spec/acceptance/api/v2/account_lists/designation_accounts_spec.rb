require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Designation Accounts' do
  include_context :json_headers
  documentation_scope = :account_lists_api_designation_accounts

  let(:resource_type) { 'designation_accounts' }
  let(:user)          { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:designation_account) { create(:designation_account) }
  let(:id)                  { designation_account.uuid }

  let(:expected_attribute_keys) do
    %w(
      active
      display_name
      balance
      balance_updated_at
      converted_balance
      created_at
      currency
      currency_symbol
      designation_number
      exchange_rate
      name
      organization_name
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before do
      account_list.designation_accounts << designation_account
      api_login(user)
    end

    get '/api/v2/account_lists/:account_list_id/designation_accounts' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'filter', 'Filter the list of returned designation_accounts'
      parameter 'filter[wildcard_search]', 'where name contains or designation_number starts with wildcard_search'
      response_field 'data',       'Data', type: 'Array[Object]'

      example 'Designation Account [LIST]', document: documentation_scope do
        explanation 'List of Designation Accounts associated to the Account List'
        do_request
        check_collection_resource(1)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/designation_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'active',             'Active',             type: 'Boolean'
        response_field 'display_name',       'Name to Display',    type: 'String'
        response_field 'balance',            'Balance',            type: 'Number'
        response_field 'balance_updated_at', 'Balance Updated At', type: 'String'
        response_field 'converted_balance',  'Converted Balance',  type: 'Number'
        response_field 'created_at',         'Created At',         type: 'String'
        response_field 'currency',           'Currency',           type: 'String'
        response_field 'currency_symbol',    'Currency Symbol',    type: 'String'
        response_field 'designation_number', 'Designation Number', type: 'String'
        response_field 'exchange_rate',      'Exchange Rate',      type: 'Number'
        response_field 'name',               'Name',               type: 'String'
        response_field 'organization_name',  'Organization Name',  type: 'String'
        response_field 'updated_at',         'Updated At',         type: 'String'
        response_field 'updated_in_db_at',   'Updated In Db At',   type: 'String'
      end

      example 'Designation Account [GET]', document: documentation_scope do
        explanation 'The Designation Account with the given ID'
        do_request
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['designation_number']).to eq designation_account.designation_number
        expect(response_status).to eq 200
      end
    end
  end
end
