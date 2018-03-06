require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists Api > Donor Accounts' do
  include_context :json_headers
  documentation_scope = :account_lists_api_donor_accounts

  let(:resource_type) { 'donor_accounts' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  let!(:contact)       { create(:contact, account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let(:id)             { donor_account.id }

  let(:expected_attribute_keys) do
    %w(
      account_number
      created_at
      display_name
      donor_type
      first_donation_date
      last_donation_date
      total_donations
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      contacts
      organization
    )
  end

  before do
    contact.donor_accounts << donor_account
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/donor_accounts' do
      parameter 'account_list_id', 'Account List ID', required: true

      parameter 'filter', 'Filter the list of returned donor_accounts'
      parameter 'filter[wildcard_search]', 'where name contains or account_number starts with wildcard_search'

      response_field 'data', 'Data', type: 'Array[Object]'

      example 'Donor Account [LIST]', document: documentation_scope do
        explanation 'List of Donor Accounts associated with the Account List'
        do_request
        check_collection_resource(1, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/donor_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'account_number',      'Account Number',      type: 'String'
        response_field 'display_name',        'Name to Display',     type: 'String'
        response_field 'contact_ids',         'Contact IDs',         type: 'Array[Number]'
        response_field 'created_at',          'Created At',          type: 'String'
        response_field 'donor_type',          'Donor Type',          type: 'String'
        response_field 'first_donation_date', 'First Donation Date', type: 'String'
        response_field 'last_donation_date',  'Last Donation Date',  type: 'String'
        response_field 'organization_id',     'Organization ID',     type: 'Number'
        response_field 'total_donations',     'Total Donations',     type: 'Number'
        response_field 'updated_at',          'Updated At',          type: 'String'
        response_field 'updated_in_db_at',    'Updated In Db At',    type: 'String'
      end

      example 'Donor Account [GET]', document: documentation_scope do
        explanation 'The Account List Donor Account with the given ID'
        do_request
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['account_number']).to eq donor_account.account_number
        expect(response_status).to eq 200
      end
    end
  end
end
