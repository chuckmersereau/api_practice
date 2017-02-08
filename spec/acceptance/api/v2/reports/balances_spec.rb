require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Designation Account Balances Report' do
  include_context :json_headers

  let(:resource_type) { 'reports_balances' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      updated_at
      updated_in_db_at
      total_currency
      total_currency_symbol
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/balances' do
      parameter 'filter[account_list_id]', 'Account List ID',                                                                            required: true
      parameter 'include',                 "Use 'include=designation_accounts' to include Designation Accounts, which include balances", required: true
      response_field 'data',               'Data object',                                                                                'Type' => 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',            'Time when report was observed',              'Type' => 'String'
        response_field 'total_currency',        'Total Currency',                             'Type' => 'String'
        response_field 'total_currency_symbol', 'The symbol representing the Total Currency', 'Type' => 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list',          'Account List',                    'Type' => 'Object'
        response_field 'designation_accounts',  'Associated Designation Accounts', 'Type' => 'Array[Object]'
      end

      example 'Balance [LIST]', document: :reports do
        explanation 'Lists balances for each Designation Account associated with the current Account List'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
