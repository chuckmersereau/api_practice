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
  before do
    contact.donor_accounts << donor_account
  end
  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account_lists/:account_list_id/donor_accounts' do
      parameter 'account-list-id',              'Account List ID', required: true
      response_field :data,                     'Data', 'Type' => 'Array'
      example_request 'list donor accounts of account list' do
        check_collection_resource(1)
        expect(resource_object.keys).to eq %w(organization-id account-number created-at updated-at
                                              total-donations last-donation-date first-donation-date donor-type contact-ids)
        expect(status).to eq 200
      end
    end
    get '/api/v2/account_lists/:account_list_id/donor_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'organization-id',         'Organization ID', 'Type' => 'Integer'
        response_field 'account-number',          'Account Number', 'Type' => 'String'
        response_field 'created-at',              'Created At', 'Type' => 'Date'
        response_field 'updated-at',              'Updated At', 'Type' => 'Date'
        response_field 'total-donations',         'Total Donations', 'Type' => 'Integer'
        response_field 'last-donation-date',      'Last Donation Date', 'Type' => 'Date'
        response_field 'first-donation-date',     'First Donation Date', 'Type' => 'Date'
        response_field 'donor-type',              'Donor Type', 'Type' => 'String'
        response_field 'contact-ids',             'Contact IDs', 'Type' => 'Array'
      end
      example_request 'get donor account' do
        check_resource
        expect(resource_object.keys).to eq %w(organization-id account-number created-at updated-at
                                              total-donations last-donation-date first-donation-date donor-type contact-ids)
        expect(resource_object['account-number']).to eq donor_account.account_number
        expect(status).to eq 200
      end
    end
  end
end
