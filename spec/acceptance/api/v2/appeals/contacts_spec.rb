require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Appeals > Contacts' do
  include_context :json_headers
  documentation_scope = :appeals_api_contacts

  let(:resource_type) { 'contacts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:appeal)       { create(:appeal, account_list: account_list) }
  let(:appeal_id)     { appeal.uuid }
  let!(:contact)      { create(:contact, account_list: account_list) }
  let!(:new_contact)  { create(:contact, account_list: account_list) }
  let(:id)            { contact.uuid }

  let(:resource_attributes) do
    %w(
      avatar
      church_name
      created_at
      deceased
      donor_accounts
      envelope_greeting
      greeting
      last_activity
      last_appointment
      last_donation
      last_letter
      last_phone_call
      last_pre_call
      last_thank
      likely_to_give
      locale
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
      send_newsletter
      square_avatar
      status
      status_valid
      suggested_changes
      tag_list
      timezone
      total_donations
      uncompleted_tasks_count
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_list
      addresses
      appeals
      contacts_referred_by_me
      contacts_that_referred_me
      donor_accounts
      last_six_donations
      people
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

      example 'Contact [LIST]', document: documentation_scope do
        explanation 'List of Contacts associated to the Appeal'
        do_request
        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq 200
      end
    end

    post 'api/v2/appeals/:appeal_id/contacts/:id' do
      let(:id) { new_contact.uuid }

      example 'Contact [POST]', document: documentation_scope do
        explanation 'Add a contact to an Appeal'
        do_request
        check_resource(%w(relationships))
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/appeals/:appeal_id/contacts/:id' do
      with_options scope: [:data,                       :attributes] do
        response_field 'church_name',                   'Church Name',             'Type' => 'String'
        response_field 'contacts_that_referred_me_ids', 'Referrals to me IDs',     'Type' => 'Array[Number]'
        response_field 'created_at',                    'Created At',              'Type' => 'String'
        response_field 'deceased',                      'Deceased',                'Type' => 'Boolean'
        response_field 'donor_accounts',                'Donor Accounts',          'Type' => 'Array[Object]'
        response_field 'last_activity',                 'Last Activity',           'Type' => 'String'
        response_field 'last_appointment',              'Last Appointment',        'Type' => 'String'
        response_field 'last_letter',                   'Last letter',             'Type' => 'String'
        response_field 'last_phone_call',               'Last phone call',         'Type' => 'String'
        response_field 'last_pre_call',                 'Last Pre-Call',           'Type' => 'String'
        response_field 'last_thank',                    'Last Thank',              'Type' => 'String'
        response_field 'likely_to_give',                'Likely to Give',          'Type' => 'String'
        response_field 'magazine',                      'Magazine',                'Type' => 'Boolean'
        response_field 'name',                          'Name',                    'Type' => 'String'
        response_field 'next_ask',                      'Next ask',                'Type' => 'String'
        response_field 'no_appeals',                    'No Appeals',              'Type' => 'Boolean'
        response_field 'notes',                         'Notes',                   'Type' => 'String'
        response_field 'notes_saved_at',                'Notes saved at',          'Type' => 'String'
        response_field 'pledge_amount',                 'Pledge Amount',           'Type' => 'Number'
        response_field 'pledge_currency',               'Pledge Currency',         'Type' => 'String'
        response_field 'pledge_currency_symbol',        'Pledge Currency Symbol',  'Type' => 'String'
        response_field 'pledge_frequency',              'Pledge Frequency',        'Type' => 'Number'
        response_field 'pledge_received',               'Pledge Received',         'Type' => 'Boolean'
        response_field 'pledge_start_date',             'Pledge Start Date',       'Type' => 'String'
        response_field 'send_newsletter',               'Send Newsletter',         'Type' => 'String'
        response_field 'status',                        'Status',                  'Type' => 'String'
        response_field 'tag_list',                      'Tag List',                'Type' => 'Array[String]'
        response_field 'timezone',                      'Timezone',                'Type' => 'String'
        response_field 'uncompleted_tasks_count',       'Uncompleted Tasks count', 'Type' => 'Number'
        response_field 'updated_at',                    'Updated At',              'Type' => 'String'
        response_field 'updated_in_db_at',              'Updated In Db At',        'Type' => 'String'
      end

      example 'Contact [GET]', document: documentation_scope do
        explanation 'The Appeal Contact with the given ID'
        do_request
        check_resource(%w(relationships))
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/appeals/:appeal_id/contacts/:id' do
      parameter 'id', 'ID', required: true

      example 'Contact [DELETE]', document: documentation_scope do
        explanation 'Remove the Contact with the given ID from the Appeal'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
