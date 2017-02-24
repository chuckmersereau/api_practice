require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Donations' do
  include_context :json_headers
  documentation_scope = :account_lists_api_donations

  let(:resource_type) { 'donations' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact)             { create(:contact, account_list: account_list) }
  let!(:donor_account)       { create(:donor_account) }
  let!(:designation_account) { create(:designation_account) }

  let!(:donations) do
    create_list(:donation, 2, donor_account: donor_account,
                              designation_account: designation_account, amount: 10.00)
  end

  let(:donation) { donations.first }
  let(:id)       { donation.uuid }

  let(:new_donation) do
    build(:donation, amount: 10.00)
      .attributes
      .reject { |attr| attr.to_s.end_with?('_id') }
      .merge(updated_in_db_at: donation.updated_at)
  end

  let(:relationships) do
    {
      donor_account: {
        data: {
          type: 'donor_accounts',
          id: donor_account.uuid
        }
      },
      designation_account: {
        data: {
          type: 'designation_accounts',
          id: designation_account.uuid
        }
      }
    }
  end

  let(:form_data) { build_data(new_donation, relationships: relationships) }

  let(:expected_attribute_keys) do
    %w(
      amount
      appeal_amount
      channel
      created_at
      currency
      donation_date
      memo
      motivation
      payment_method
      payment_type
      remote_id
      tendered_amount
      tendered_currency
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      appeal
      contact
      designation_account
      donor_account
    )
  end

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/donations' do
      parameter 'account_list_id',        'Account List ID', required: true
      parameter 'filters[donation_date]', 'A donation date range'
      response_field 'data',              'Data', 'Type' => 'Array[Object]'

      example 'Donation [LIST]', document: documentation_scope do
        explanation 'List of Donations associated with the the Account List'
        do_request
        check_collection_resource(2, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/donations/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'amount',                 'Amount',                 'Type' => 'Number'
        response_field 'appeal_amount',          'Appeal Amount',          'Type' => 'Number'
        response_field 'appeal_id',              'Appeal ID',              'Type' => 'Number'
        response_field 'channel',                'Channel',                'Type' => 'String'
        response_field 'contact_id',             'Contact ID',             'Type' => 'Number'
        response_field 'created_at',             'Created At',             'Type' => 'String'
        response_field 'currency',               'Currency',               'Type' => 'String'
        response_field 'designation_account_id', 'Designation Account ID', 'Type' => 'Number'
        response_field 'donation_date',          'Donation Date',          'Type' => 'String'
        response_field 'donor_account_id',       'Donor Account ID',       'Type' => 'Number'
        response_field 'memo',                   'Memo',                   'Type' => 'String'
        response_field 'motivation',             'Motivation',             'Type' => 'String'
        response_field 'payment_method',         'Payment Method',         'Type' => 'String'
        response_field 'payment_type',           'Payment Type',           'Type' => 'String'
        response_field 'remote_id',              'Remote ID',              'Type' => 'Number'
        response_field 'tendered_amount',        'Tendered Ammount',       'Type' => 'Number'
        response_field 'tendered_currency',      'Tendered Currency',      'Type' => 'String'
        response_field 'updated_at',             'Updated At',             'Type' => 'String'
        response_field 'updated_in_db_at',       'Updated In Db At',       'Type' => 'String'
      end

      example 'Donation [GET]', document: documentation_scope do
        explanation 'The Account List Donation with the given ID'
        do_request
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['amount']).to eq '$10'
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/account_lists/:account_list_id/donations' do
      with_options scope: [:data, :attributes] do
        parameter 'amount',                 'Amount'
        parameter 'appeal_amount',          'Appeal Amount'
        parameter 'appeal_id',              'Appeal ID'
        parameter 'contact_id',             'Contact ID'
        parameter 'designation_account_id', 'Designation Account ID'
        parameter 'donation_date',          'Donation Date'
        parameter 'donor_account_id',       'Donor Account ID'
      end

      example 'Donation [CREATE]', document: documentation_scope do
        explanation 'Creates a new Donation associated with the Account List'
        do_request data: form_data

        expect(resource_object['amount']).to eq '$10'
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/account_lists/:account_list_id/donations/:id' do
      parameter 'id', 'ID of the donation', required: true

      with_options scope: [:data, :attributes] do
        parameter 'amount',                 'Amount'
        parameter 'appeal_amount',          'Appeal Amount'
        parameter 'appeal_id',              'Appeal ID'
        parameter 'contact_id',             'Contact ID'
        parameter 'designation_account_id', 'Designation Account ID'
        parameter 'donation_date',          'Donation Date'
        parameter 'donor_account_id',       'Donor Account ID'
      end

      example 'Donation [UPDATE]', document: documentation_scope do
        explanation 'Updates a Donation associated with the Account List'
        do_request data: build_data(new_donation)

        expect(resource_object['amount']).to eq '$10'
        expect(response_status).to eq 200
      end
    end
  end
end
