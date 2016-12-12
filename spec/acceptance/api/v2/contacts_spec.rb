require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts' do
  include_context :json_headers

  let(:resource_type) { 'contacts' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact) { create(:contact, account_list: account_list) }
  let(:id)       { contact.id }

  let(:new_contact) { build(:contact, account_list: account_list).attributes }
  let(:form_data)   { build_data(new_contact) }

  let(:additional_keys) { ['relationships'] }

  let(:expected_keys) do
    %w(
      avatar
      church_name
      created_at
      deceased
      donor_accounts
      last_activity
      last_appointment
      last_letter
      last_phone_call
      last_pre_call
      last_thank
      likely_to_give
      magazine
      name
      next_ask
      no_appeals
      notes
      notes_saved_at
      pledge_amount
      pledge_currency
      pledge_currency_symbol
      pledge_frequency
      pledge_received
      pledge_start_date
      referrals_to_me_ids
      send_newsletter
      square_avatar
      status
      tag_list
      timezone
      uncompleted_tasks_count
      updated_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts' do
      response_field :data, 'Data', 'Type' => 'Array[Object]'

      example 'Contact [LIST]', document: :entities do
        explanation 'List of Contacts'
        do_request
        check_collection_resource(1, additional_keys)
        expect(resource_object.keys).to match_array(expected_keys)
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',     'Account List ID'
        parameter 'church_name',         'Church Name'
        parameter 'direct_deposit',      'Direct Deposite'
        parameter 'envelope_greeting',   'Envelope Greeting'
        parameter 'full_name',           'Full Name'
        parameter 'greeting',            'Greeting'
        parameter 'likely_to_give',      'Likely To Give'
        parameter 'locale',              'Locale'
        parameter 'magazine',            'Magazine'
        parameter 'name',                'Contact Name'
        parameter 'next_ask',            'Next Ask'
        parameter 'no_appeals',          'No Appeals'
        parameter 'not_duplicated_with', 'IDs of contacts that are known to not be duplicates'
        parameter 'notes',               'Notes'
        parameter 'pledge_amount',       'Pledge Amount'
        parameter 'pledge_currency',     'Pledge Currency'
        parameter 'pledge_frequency',    'Pledge Frequency'
        parameter 'pledge_received',     'Pledge Received'
        parameter 'pledge_start_date',   'Pledge Start Date'
        parameter 'primary_person_id',   'Primary Person ID'
        parameter 'send_newsletter',     'Send Newsletter'
        parameter 'status',              'Status'
        parameter 'tag_list',            'Tag List'
        parameter 'timezone',            'Time Zone'
        parameter 'website',             'Website'
      end

      example 'Contact [CREATE]', document: :entities do
        explanation 'Create a Contact'
        do_request data: form_data
        expect(resource_object['name']).to eq new_contact['name']
        expect(response_status).to eq 201
      end
    end

    get '/api/v2/contacts/:id' do
      parameter :id, 'ID of the Contact', required: true
      with_options scope: [:data, :attributes] do
        response_field 'avatar',                  'Avatar',                  'Type' => 'String'
        response_field 'church_name',             'Church Name',             'Type' => 'String'
        response_field 'created_at',              'Created At',              'Type' => 'String'
        response_field 'deceased',                'Deceased',                'Type' => 'Boolean'
        response_field 'donor_accounts',          'Donor Accounts',          'Type' => 'Array[Object]'
        response_field 'last_activity',           'Last Activity',           'Type' => 'String'
        response_field 'last_appointment',        'Last Appointment',        'Type' => 'String'
        response_field 'last_letter',             'Last Letter',             'Type' => 'String'
        response_field 'last_phone_call',         'Last Phone Call',         'Type' => 'String'
        response_field 'last_pre_call',           'Last Pre Call',           'Type' => 'String'
        response_field 'last_thank',              'Last Thank',              'Type' => 'String'
        response_field 'likely_to_give',          'Likely to Give',          'Type' => 'String'
        response_field 'magazine',                'Magazine',                'Type' => 'Boolean'
        response_field 'name',                    'Contact Name',            'Type' => 'String'
        response_field 'next_ask',                'Next Ask',                'Type' => 'String'
        response_field 'no_appeals',              'No Appeals',              'Type' => 'Boolean'
        response_field 'notes',                   'Notes',                   'Type' => 'String'
        response_field 'notes_saved_at',          'Notes Saved At',          'Type' => 'String'
        response_field 'pledge_amount',           'Pledge Amount',           'Type' => 'Number'
        response_field 'pledge_currency',         'Pledge Currency',         'Type' => 'String'
        response_field 'pledge_currency_symbol',  'Pledge Currency Symbol',  'Type' => 'String'
        response_field 'pledge_frequency',        'Pledge Frequency',        'Type' => 'String'
        response_field 'pledge_received',         'Pledge Received',         'Type' => 'Boolean'
        response_field 'pledge_start_date',       'Pledge Start Date',       'Type' => 'String'
        response_field 'referrals_to_me_ids',     'IDs of Refferals to me',  'Type' => 'Array[Number]'
        response_field 'send_newsletter',         'Send Newsletter',         'Type' => 'String'
        response_field 'square_avatar',           'Square Avatar',           'Type' => 'String'
        response_field 'status',                  'Status',                  'Type' => 'String'
        response_field 'tag_list',                'Tags',                    'Type' => 'Array[String]'
        response_field 'timezone',                'Time Zone',               'Type' => 'String'
        response_field 'uncompleted_tasks_count', 'Uncompleted Tasks Count', 'Type' => 'Number'
        response_field 'updated_at',              'Updated At',              'Type' => 'String'
      end

      example 'Contact [GET]', document: :entities do
        explanation 'The Contact with the given ID'
        do_request
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

      example 'Contact [UPDATE]', document: :entities do
        explanation 'Update the Contact with the given ID'
        do_request data: form_data
        expect(resource_object['name']).to eq new_contact['name']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:id' do
      parameter :id, 'ID of the Contact', required: true
      example 'Contact [DELETE]', document: :entities do
        explanation 'Delete Contact with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
