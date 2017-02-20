require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Account Goal Progress Report' do
  include_context :json_headers
  documentation_scope = :reports_api_goal_progress

  let(:resource_type) { 'reports_goal_progresses' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      in_hand_percent
      monthly_goal
      pledged_percent
      received_pledges
      salary_balance
      salary_currency_or_default
      salary_organization_id
      total_pledges
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/goal_progress' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      response_field 'data',               'Data object',     'Type' => 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',                 'Time when report was observed',           'Type' => 'String'
        response_field 'in_hand_percent',            'Percent of monthly goal in hand',         'Type' => 'String'
        response_field 'monthly_goal',               'The account list monthly goal',           'Type' => 'String'
        response_field 'pledged_percent',            'Percent of monthly goal pledged',         'Type' => 'String'
        response_field 'received_pledges',           'Percent of monthly goal received',        'Type' => 'String'
        response_field 'salary_balance',             'Balance of organization salary accounts', 'Type' => 'String'
        response_field 'salary_currency_or_default', 'Currency of salary',                      'Type' => 'String'
        response_field 'salary_organization_id',     'ID of salary Organization',               'Type' => 'String'
        response_field 'total_pledges',              'Total pledges',                           'Type' => 'String'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list', 'Account List', 'Type' => 'Object'
      end

      example 'Goal Progress [LIST]', document: documentation_scope do
        explanation 'Lists information related to the progress towards the current Account List monthly goal'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
