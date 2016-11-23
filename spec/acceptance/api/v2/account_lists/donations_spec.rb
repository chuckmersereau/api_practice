require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Donations' do
  let(:resource_type) { 'donations' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:donor_account) { create(:donor_account) }
  let!(:designation_account) { create(:designation_account) }
  let!(:donations) { create_list(:donation, 2, donor_account: donor_account, designation_account: designation_account, amount: 10.00) }
  let(:donation) { donations.first }
  let(:id) { donation.id }
  let(:new_donation) { build(:donation, donor_account: donor_account, designation_account: designation_account, amount: 10.00).attributes }
  let(:form_data) { build_data(new_donation) }
  let(:expected_attribute_keys) do
    %w(amount
       appeal-amount
       appeal-id
       channel
       contact-id
       created-at
       currency
       designation-account-id
       donation-date
       donor-account-id
       memo
       motivation
       payment-method
       payment-type
       remote-id
       tendered-amount
       tendered-currency
       updated-at)
  end

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end
  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account-lists/:account_list_id/donations' do
      parameter 'account-list-id',              'Account List ID', required: true
      response_field 'data',                    'Data', 'Type' => 'Array[Object]'
      example_request 'list donations of account list' do
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/account-lists/:account_list_id/donations/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'amount',                  'Amount', 'Type' => 'Number'
        response_field 'appeal-amount',           'Appeal Amount', 'Type' => 'Number'
        response_field 'appeal-id',               'Appeal ID', 'Type' => 'Number'
        response_field 'channel',                 'Channel', 'Type' => 'String'
        response_field 'contact-id',              'Contact ID', 'Type' => 'Number'
        response_field 'currency',                'Currency', 'Type' => 'String'
        response_field 'designation-account-id',  'Designation Account ID', 'Type' => 'Number'
        response_field 'donation-date',           'Donation Date', 'Type' => 'String'
        response_field 'donor-account-id',        'Donor Account ID', 'Type' => 'Number'
        response_field 'memo',                    'Memo', 'Type' => 'String'
        response_field 'motivation',              'Motivation', 'Type' => 'String'
        response_field 'payment-method',          'Payment Method', 'Type' => 'String'
        response_field 'payment-type',            'Payment Type', 'Type' => 'String'
        response_field 'remote-id',               'Remote ID', 'Type' => 'Number'
        response_field 'tendered-amount',         'Tendered Ammount', 'Type' => 'Number'
        response_field 'tendered-currency',       'Tendered Currency', 'Type' => 'String'
      end
      example_request 'get donation' do
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['amount']).to eq '$10'
        expect(status).to eq 200
      end
    end
    post '/api/v2/account-lists/:account_list_id/donations' do
      with_options scope: [:data, :attributes] do
        parameter 'amount',                       'Amount'
        parameter 'appeal-amount',                'Appeal Amount'
        parameter 'appeal-id',                    'Appeal ID'
        parameter 'contact-id',                   'Contact ID'
        parameter 'designation-account-id',       'Designation Account ID'
        parameter 'donation-date',                'Donation Date'
        parameter 'donor-account-id',             'Donor Account ID'
      end
      example 'create donation' do
        do_request data: form_data
        expect(resource_object['amount']).to eq '$10'
        expect(status).to eq 200
      end
    end
    put '/api/v2/account-lists/:account_list_id/donations/:id' do
      parameter 'id', 'ID of the donation', required: true
      with_options scope: [:data, :attributes] do
        parameter 'amount',                       'Amount'
        parameter 'appeal-amount',                'Appeal Amount'
        parameter 'appeal-id',                    'Appeal ID'
        parameter 'contact-id',                   'Contact ID'
        parameter 'designation-account-id',       'Designation Account ID'
        parameter 'donation-date',                'Donation Date'
        parameter 'donor-account-id',             'Donor Account ID'
      end
      example 'update donation' do
        do_request data: build_data(new_donation)
        expect(resource_object['amount']).to eq '$10'
        expect(status).to eq 200
      end
    end
  end
end
