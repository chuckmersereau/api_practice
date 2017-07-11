require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Reports > Donation Monthly Totals Report' do
  include_context :json_headers
  documentation_scope = :reports_api_donation_summaries

  let(:resource_type) { 'reports_donation_monthly_totals' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      donation_totals_by_month
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/donation_monthly_totals' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      parameter 'filter[month_range]',     'Month Range',     required: true

      with_options scope: [:data, :attributes] do
        response_field 'donation_totals_by_month', 'The donations amount for each currency by month.', type: 'Array[Object]'
      end

      example 'Donation Summary [LIST]', document: documentation_scope do
        explanation 'Lists donors who donated in the past 12 months, separated by into currency groups'
        do_request(filter: { account_list_id: account_list_id, month_range: (4.months.ago..2.months.ago).to_s })
        check_resource([])
        expect(json_response['data']['attributes']['donation_totals_by_month']).to be_an(Array)
        expect(response_status).to eq 200
      end
    end
  end
end
