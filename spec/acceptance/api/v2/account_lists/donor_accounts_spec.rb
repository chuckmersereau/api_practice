require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Donor Accounts' do
  let(:resource_type) { 'donor-accounts' }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let(:id) { donor_account.id }
  let(:expected_attribute_keys) do
    %w(organization-id account-number created-at updated-at
       total-donations last-donation-date first-donation-date donor-type contact-ids)
  end
  before do
    contact.donor_accounts << donor_account
  end
  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account_lists/:account_list_id/donor-accounts' do
      parameter 'account-list-id',              'Account List ID', required: true
      response_field :data,                     'Data', 'Type' => 'Array[Object]'
      example_request 'list donor accounts of account list' do
        check_collection_resource(1)
        expect(resource_object.keys).to eq expected_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/account_lists/:account_list_id/donor-accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'organization-id',         'Organization ID', 'Type' => 'Number'
        response_field 'account-number',          'Account Number', 'Type' => 'String'
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
        response_field 'total-donations',         'Total Donations', 'Type' => 'Number'
        response_field 'last-donation-date',      'Last Donation Date', 'Type' => 'String'
        response_field 'first-donation-date',     'First Donation Date', 'Type' => 'String'
        response_field 'donor-type',              'Donor Type', 'Type' => 'String'
        response_field 'contact-ids',             'Contact IDs', 'Type' => 'Array[Number]'
      end
      example_request 'get donor account' do
        check_resource
        expect(resource_object.keys).to eq expected_attribute_keys
        expect(resource_object['account-number']).to eq donor_account.account_number
        expect(status).to eq 200
      end
    end
  end
end
