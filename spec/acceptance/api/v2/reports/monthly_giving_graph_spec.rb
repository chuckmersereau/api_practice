require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Monthly Giving Graph Report' do
  include_context :json_headers
  documentation_scope = :reports_api_monthly_giving

  let(:resource_type) { 'reports_monthly_giving_graphs' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      display_currency
      monthly_average
      monthly_goal
      months_to_dates
      multi_currency
      pledges
      salary_currency
      salary_currency_symbol
      totals
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/monthly_giving_graph' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      response_field 'data',               'Data object',     type: 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',             'Time when report was observed',           type: 'String'
        response_field 'display_currency',       'The currency converted values are in',    type: 'String'
        response_field 'monthly_average',        'Average monthly total conversion',        type: 'Number'
        response_field 'monthly_goal',           'The Account List\'s monthly goal',        type: 'Number'
        response_field 'pledges',                'The sum of all pledges',                  type: 'Array'
        response_field 'months_to_dates',        'The first day of each month represented', type: 'Array'
        response_field 'multi_currency',         'If multiple currencies are used',         type: 'Boolean'
        response_field 'salary_currency',        'Salary currency',                         type: 'String'
        response_field 'salary_currency_symbol', 'Salary currency symbol',                  type: 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list', 'Account List', type: 'Object'
      end

      example 'Monthly Giving Graph [LIST]', document: documentation_scope do
        explanation 'Lists information related to the Monthly Giving Graph'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
