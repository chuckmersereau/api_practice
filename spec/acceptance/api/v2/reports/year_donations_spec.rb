require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Year Donations Report' do
  include_context :json_headers

  let(:resource_type) { 'reports_year_donations' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      donation_infos
      donor_infos
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/reports/year_donations' do
      parameter 'filter[account_list_id]', 'Account List ID', required: true
      response_field 'data',               'Data object',     'Type' => 'Object'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',     'Time when report was observed', 'Type' => 'String'
        response_field 'donor_infos',    'Info on donors',                'Type' => 'Array[Object]'
        response_field 'donation_infos', 'Info on donations',             'Type' => 'Array[Object]'
      end

      with_options scope: [:data, :relationships] do
        response_field 'account_list', 'Account List', 'Type' => 'Object'
      end

      example 'Donation Summary [LIST]', document: :reports do
        explanation 'Lists donors who donated in the past 12 months, along with their donation totals (related to the given Account List)'
        do_request(filter: { account_list_id: account_list_id })
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end