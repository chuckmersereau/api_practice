require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Expected Monthly Totals Report' do
  include_context :json_headers
  documentation_scope = :reports_api_monthly_totals

  let(:resource_type) { 'reports_expected_monthly_totals' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let(:resource_attributes) do
    %w(
      created_at
      expected_donations
      total_currency
      total_currency_symbol
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/expected_monthly_totals' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      parameter 'filter[donor_account_id]', 'List of Donor Account Ids', 'Type' => 'Array[String]'
      parameter 'filter[designation_account_id]', 'List of Designation Account Ids', 'Type' => 'Array[String]'
      response_field 'data', 'Data object', type: 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',            'Time when report was observed',              type: 'String'
        response_field 'expected_donations',    'Info about recieved and possible donations', type: 'Array[Object]'
        response_field 'total_currency',        'Total currency',                             type: 'String'
        response_field 'total_currency_symbol', 'Total currency symbol',                      type: 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list', 'Account List', type: 'Object'
      end

      example 'Expected Monthly Total [LIST]', document: documentation_scope do
        explanation 'Lists received and possible donations for the current month'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
