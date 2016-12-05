require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Donor Accounts' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'donor_accounts' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact)       { create(:contact, account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let(:id)             { donor_account.id }

  let(:expected_attribute_keys) do
    %w(
      account_number
      contact_ids
      created_at
      donor_type
      first_donation_date
      last_donation_date
      organization_id
      total_donations
      updated_at
    )
  end

  before do
    contact.donor_accounts << donor_account
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/donor_accounts' do
      parameter 'account_list_id', 'Account List ID', required: true
      response_field 'data', 'Data', 'Type' => 'Array[Object]'

      example 'Donor Account [LIST]', document: :account_lists do
        do_request
        check_collection_resource(1)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/donor_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'account_number',      'Account Number',      'Type' => 'String'
        response_field 'contact_ids',         'Contact IDs',         'Type' => 'Array[Number]'
        response_field 'created_at',          'Created At',          'Type' => 'String'
        response_field 'donor_type',          'Donor Type',          'Type' => 'String'
        response_field 'first_donation_date', 'First Donation Date', 'Type' => 'String'
        response_field 'last_donation_date',  'Last Donation Date',  'Type' => 'String'
        response_field 'organization_id',     'Organization ID',     'Type' => 'Number'
        response_field 'total_donations',     'Total Donations',     'Type' => 'Number'
        response_field 'updated_at',          'Updated At',          'Type' => 'String'
      end

      example 'Donor Account [GET]', document: :account_lists do
        do_request
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['account_number']).to eq donor_account.account_number
        expect(response_status).to eq 200
      end
    end
  end
end
