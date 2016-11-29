require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts' do
  let(:resource_type) { 'contacts' }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let(:new_contact) { build(:contact, account_list: account_list).attributes }
  let!(:contact) { create(:contact, account_list: account_list) }
  let(:id) { contact.id }
  let(:form_data) { build_data(new_contact) }
  let(:additional_keys) { ['relationships'] }
  let(:expected_keys) do
    %w(
      avatar
      church-name
      created-at
      deceased
      donor-accounts
      last-activity
      last-appointment
      last-letter
      last-phone-call
      last-pre-call
      last-thank
      likely-to-give
      magazine
      name
      next-ask
      no-appeals
      notes
      notes-saved-at
      pledge-amount
      pledge-currency
      pledge-currency-symbol
      pledge-frequency
      pledge-received
      pledge-start-date
      referrals-to-me-ids
      send-newsletter
      square-avatar
      status
      tag-list
      timezone
      uncompleted-tasks-count
      updated-at
    )
  end

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/contacts' do
      response_field :data, 'Data', 'Type' => 'Array'
      example_request 'list contacts of current user' do
        check_collection_resource(1, additional_keys)
        expect(resource_object.keys).to match_array(expected_keys)
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id', 'Account List ID'
        parameter 'church_name', 'Church Name'
        parameter 'direct_deposit', 'Direct Deposite'
        parameter 'envelope_greeting', 'Envelope Greeting'
        parameter 'full_name', 'Full Name'
        parameter 'greeting', 'Greeting'
        parameter 'likely_to_give', 'Likely To Give'
        parameter 'locale', 'Locale'
        parameter 'magazine', 'Magazine'
        parameter 'name', 'Contact Name'
        parameter 'next_ask', 'Next Ask'
        parameter 'no_appeals', 'No Appeals'
        parameter 'not_duplicated_with', 'IDs of contacts that are known to not be duplicates'
        parameter 'notes', 'Notes'
        parameter 'pledge_amount', 'Pledge Amount'
        parameter 'pledge_currency', 'Pledge Currency'
        parameter 'pledge_frequency', 'Pledge Frequency'
        parameter 'pledge_received', 'Pledge Received'
        parameter 'pledge_start_date', 'Pledge Start Date'
        parameter 'primary_person_id', 'Primary Person ID'
        parameter 'send_newsletter', 'Send Newsletter'
        parameter 'status', 'Status'
        parameter 'tag_list', 'Tag List'
        parameter 'timezone', 'Time Zone'
        parameter 'website', 'Website'
      end

      example 'create contact' do
        do_request data: form_data
        expect(resource_object['name']).to eq new_contact['name']
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:id' do
      parameter :id, 'ID of the Contact', required: true
      with_options scope: [:data, :attributes] do
        response_field 'avatar',                  'Avatar',                  'Type' => 'String'
        response_field 'church-name',             'Church Name',             'Type' => 'String'
        response_field 'created-at',              'Created At',              'Type' => 'String'
        response_field 'deceased',                'Deceased',                'Type' => 'Boolean'
        response_field 'donor-accounts',          'Donor Accounts',          'Type' => 'Array[Object]'
        response_field 'last-activity',           'Last Activity',           'Type' => 'String'
        response_field 'last-appointment',        'Last Appointment',        'Type' => 'String'
        response_field 'last-letter',             'Last Letter',             'Type' => 'String'
        response_field 'last-phone-call',         'Last Phone Call',         'Type' => 'String'
        response_field 'last-pre-call',           'Last Pre Call',           'Type' => 'String'
        response_field 'last-thank',              'Last Thank',              'Type' => 'String'
        response_field 'likely-to-give',          'Likely to Give',          'Type' => 'String'
        response_field 'magazine',                'Magazine',                'Type' => 'Boolean'
        response_field 'name',                    'Contact Name',            'Type' => 'String'
        response_field 'next-ask',                'Next Ask',                'Type' => 'String'
        response_field 'no-appeals',              'No Appeals',              'Type' => 'Boolean'
        response_field 'notes',                   'Notes',                   'Type' => 'String'
        response_field 'notes-saved-at',          'Notes Saved At',          'Type' => 'String'
        response_field 'pledge-amount',           'Pledge Amount',           'Type' => 'Number'
        response_field 'pledge-currency',         'Pledge Currency',         'Type' => 'String'
        response_field 'pledge-currency-symbol',  'Pledge Currency Symbol',  'Type' => 'String'
        response_field 'pledge-frequency',        'Pledge Frequency',        'Type' => 'String'
        response_field 'pledge-received',         'Pledge Received',         'Type' => 'Boolean'
        response_field 'pledge-start-date',       'Pledge Start Date',       'Type' => 'String'
        response_field 'referrals-to-me-ids',     'IDs of Refferals to me',  'Type' => 'Array[Number]'
        response_field 'send-newsletter',         'Send Newsletter',         'Type' => 'String'
        response_field 'square-avatar',           'Square Avatar',           'Type' => 'String'
        response_field 'status',                  'Status',                  'Type' => 'String'
        response_field 'tag-list',                'Tags',                    'Type' => 'Array[String]'
        response_field 'timezone',                'Time Zone',               'Type' => 'String'
        response_field 'uncompleted-tasks-count', 'Uncompleted Tasks Count', 'Type' => 'Number'
        response_field 'updated-at',              'Updated At',              'Type' => 'String'
      end

      example_request 'get contact' do
        check_resource(additional_keys)
        expect(resource_object.keys).to match_array(expected_keys)
        expect(resource_object['name']).to eq contact.name
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/contacts/:id' do
      parameter :id, 'ID of the Contact', required: true
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id', 'Account List ID'
        parameter 'church_name', 'Church Name'
        parameter 'direct_deposit', 'Direct Deposite'
        parameter 'envelope_greeting', 'Envelope Greeting'
        parameter 'full_name', 'Full Name'
        parameter 'greeting', 'Greeting'
        parameter 'likely_to_give', 'Likely To Give'
        parameter 'locale', 'Locale'
        parameter 'magazine', 'Magazine'
        parameter 'name', 'Contact Name'
        parameter 'next_ask', 'Next Ask'
        parameter 'no_appeals', 'No Appeals'
        parameter 'not_duplicated_with', 'IDs of contacts that are known to not be duplicates'
        parameter 'notes', 'Notes'
        parameter 'pledge_amount', 'Pledge Amount'
        parameter 'pledge_currency', 'Pledge Currency'
        parameter 'pledge_frequency', 'Pledge Frequency'
        parameter 'pledge_received', 'Pledge Received'
        parameter 'pledge_start_date', 'Pledge Start Date'
        parameter 'primary_person_id', 'Primary Person ID'
        parameter 'send_newsletter', 'Send Newsletter'
        parameter 'status', 'Status'
        parameter 'tag_list', 'Tag List'
        parameter 'timezone', 'Time Zone'
        parameter 'website', 'Website'
      end

      example 'update contact' do
        do_request data: form_data
        expect(resource_object['name']).to eq new_contact['name']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:id' do
      parameter :id, 'ID of the Contact', required: true
      example 'delete contact' do
        do_request
        expect(response_status).to eq 200
      end
    end
  end
end
