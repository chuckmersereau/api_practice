require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Monthly Giving Graph Report' do
  include_context :json_headers

  let(:resource_type) { 'reports_monthly_giving_graphs' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      updated_at
      updated_in_db_at
      monthly_average
      monthly_goal
      months_to_dates
      pledges
      totals
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/monthly_giving_graph' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      response_field 'data',               'Data object',     'Type' => 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',      'Time when report was observed',           'Type' => 'String'
        response_field 'monthly_average', 'Average monthly total conversion',        'Type' => 'Number'
        response_field 'monthly_goal',    'The Account List\'s monthly goal',        'Type' => 'Number'
        response_field 'pledges',         'The sum of all pledges',                  'Type' => 'Array'
        response_field 'months_to_dates', 'The first day of each month represented', 'Type' => 'Array'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list', 'Account List', 'Type' => 'Object'
      end

      example 'show report' do
        explanation 'Lists balances for each Designation Account associated with the current Account List'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
