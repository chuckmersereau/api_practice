require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts' do
  include_context :json_headers

  let(:resource_type) { 'contact' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:appeal)   { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.id }
  let!(:contact)  { create(:contact, account_list_id: account_list_id) }
  let(:id)        { contact.id }

  let(:expected_attribute_keys) do
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
    before do
      appeal.contacts << contact
      api_login(user)
    end

    get '/api/v2/appeals/:appeal_id/contacts' do
      parameter 'account_list_id', 'Account List ID', scope: :filters
      response_field 'data',       'Data', 'Type' => 'Array[Object]'

      example 'Contact [LIST]', document: :appeals do
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/appeals/:appeal_id/contacts/:id' do
      parameter 'account_list_id',              'Account List ID', required: true, scope: :filters

      with_options scope: [:data, :attributes] do
        response_field 'church_name',             'Church Name',             'Type' => 'String'
        response_field 'deceased',                'Deceased',                'Type' => 'Boolean'
        response_field 'donor_accounts',          'Donor Accounts',          'Type' => 'Array[Object]'
        response_field 'last_activity',           'Last Activity',           'Type' => 'String'
        response_field 'last_appointment',        'Last Appointment',        'Type' => 'String'
        response_field 'last_letter',             'Last letter',             'Type' => 'String'
        response_field 'last_phone_call',         'Last phone call',         'Type' => 'String'
        response_field 'last_pre_call',           'Last Pre-Call',           'Type' => 'String'
        response_field 'last_thank',              'Last Thank',              'Type' => 'String'
        response_field 'likely_to_give',          'Likely to Give',          'Type' => 'String'
        response_field 'magazine',                'Magazine',                'Type' => 'Boolean'
        response_field 'name',                    'Name',                    'Type' => 'String'
        response_field 'next_ask',                'Next ask',                'Type' => 'String'
        response_field 'no_appeals',              'No Appeals',              'Type' => 'Boolean'
        response_field 'notes',                   'Notes',                   'Type' => 'String'
        response_field 'notes_saved_at',          'Notes saved at',          'Type' => 'String'
        response_field 'pledge_amount',           'Pledge Amount',           'Type' => 'Number'
        response_field 'pledge_currency',         'Pledge Currency',         'Type' => 'String'
        response_field 'pledge_currency_symbol',  'Pledge Currency Symbol',  'Type' => 'String'
        response_field 'pledge_frequency',        'Pledge Frequency',        'Type' => 'Number'
        response_field 'pledge_received',         'Pledge Received',         'Type' => 'Boolean'
        response_field 'pledge_start_date',       'Pledge Start Date',       'Type' => 'String'
        response_field 'referrals_to_me_ids',     'Referrals to me IDs',     'Type' => 'Array[Number]'
        response_field 'send_newsletter',         'Send Newsletter',         'Type' => 'String'
        response_field 'status',                  'Status',                  'Type' => 'String'
        response_field 'tag_list',                'Tag List',                'Type' => 'Array[String]'
        response_field 'timezone',                'Timezone',                'Type' => 'String'
        response_field 'uncompleted_tasks_count', 'Uncompleted Tasks count', 'Type' => 'Number'
      end

      example 'Contact [GET]', document: :appeals do
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/appeals/:appeal_id/contacts/:id' do
      parameter 'account_list_id', 'Account List ID', scope: :filters
      parameter 'id',              'ID', required: true

      example 'Contact [DELETE]', document: :appeals do
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
