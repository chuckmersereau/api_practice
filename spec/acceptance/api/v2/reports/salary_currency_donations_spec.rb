require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Salary Currency Donations Report' do
  include_context :json_headers
  documentation_scope = :reports_api_donation_summaries

  let(:resource_type) { 'reports_salary_currency_donations' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let(:resource_attributes) do
    %w(
      created_at
      donor_infos
      months
      currency_groups
      salary_currency
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/salary_currency_donations' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      response_field 'data',               'Data object',     type: 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',      'Time when report was observed',                                     type: 'String'
        response_field 'donor_infos',     'Info on donors',                                                    type: 'Array[Object]'
        response_field 'months',          'The months represented in the data',                                type: 'Array[Object]'
        response_field 'currency_groups', 'The donations made each month, per contact, grouped by currencies', type: 'Array[Object]'
      end

      with_options scope: [:data, :attributes, :currency_groups, :currency_code] do
        response_field 'totals',         'The total donations for the year, and each individual month', type: 'Object'
        response_field 'donation_infos', 'Info on each contact\'s donations each month of the year',    type: 'Array[Object]'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list', 'Account List', type: 'Object'
      end

      example 'Donation Summary [LIST]', document: documentation_scope do
        explanation 'Lists donors who donated in the past 12 months, in the account list\'s salary currency'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
