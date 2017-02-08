require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account List Analytics' do
  include_context :json_headers

  let(:resource_type) { 'account_list_analytics' }
  let(:user) { create(:user_with_account) }
  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:resource_attributes) do
    %w(
      appointments
      contacts
      correspondence
      created_at
      electronic
      email
      end_date
      facebook
      phone
      start_date
      text_message
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/account_lists/:account_list_id/analytics' do
      parameter 'account_list_id',    'Account List ID', required: true
      parameter 'filter[start_date]', 'Starting Date for Analytics, in ISO8601'
      parameter 'filter[end_date]',   'Ending Date for Analytics, in ISO8601'

      with_options scope: [:data, :attributes] do
        response_field 'appointments',   'Appointment related analytics',      'Type' => 'Object'
        response_field 'contacts',       'Contact related analytics',          'Type' => 'Object'
        response_field 'correspondence', 'Correspondence related analytics',   'Type' => 'Object'
        response_field 'created_at',     'Time when analytics were observed',  'Type' => 'String'
        response_field 'electronic',     'Electronic related analytics',       'Type' => 'Object'
        response_field 'email',          'Email related analytics',            'Type' => 'Object'
        response_field 'end_date',       'Ending date for analytics period',   'Type' => 'String'
        response_field 'facebook',       'Facebook related analytics',         'Type' => 'Object'
        response_field 'phone',          'Phone related analytics',            'Type' => 'Object'
        response_field 'start_date',     'Starting date for analytics period', 'Type' => 'String'
        response_field 'text_message',   'Text message related analytics',     'Type' => 'Object'
        response_field 'updated_at',     'Time when analytics were observed',  'Type' => 'String'
      end

      example 'Analytics for the past 30 days [GET]', document: :account_lists do
        explanation 'List analytics related to the Account List for the past 30 days'
        do_request(account_list_id: account_list_id)
        check_resource

        expect(response_status).to eq 200
      end

      example 'Analytics for a custom date range [GET]', document: :account_lists do
        explanation 'List analytics related to the Account List with a start and end date'
        do_request(account_list_id: account_list_id, filter: { start_date: 1.week.ago.iso8601, end_date: Time.current.iso8601 })
        check_resource

        expect(response_status).to eq 200
      end
    end
  end
end
