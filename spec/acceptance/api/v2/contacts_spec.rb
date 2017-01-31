require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts' do
  include_context :json_headers

  let(:resource_type) { 'contacts' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact) { create(:contact, account_list: account_list) }
  let(:id)       { contact.uuid }

  let(:new_contact) do
    build(:contact).attributes
                   .except(:first_donation_date, :notes_saved_at,
                           :last_activity, :last_appointment,
                           :last_donation_date, :last_letter,
                           :last_phone_call, :last_pre_call,
                           :last_thank, :late_at, :prayer_letters_id,
                           :pls_id, :prayer_letters_params,
                           :tnt_id, :total_donations,
                           :uncompleted_tasks_count)
                   .merge(account_list_id: account_list.uuid,
                          updated_in_db_at: contact.updated_at)
  end
  let(:form_data) { build_data(new_contact) }

  let(:bulk_update_form_data) do
    [{ data: { id: contact.uuid, attributes: new_contact } }]
  end

  let(:additional_keys) { ['relationships'] }

  let(:resource_attributes) do
    %w(
      account_list_id
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
      donor_accounts
      people
      referrals_by_me
      referrals_to_me
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts' do
      parameter 'filters[account_list_id]',            'Filter by Account List; Accepts Account List ID',                                                     required: false
      parameter 'filters[address_historic]',           'Filter by Address No Longer Valid; Accepts values "true", or "false"',                                required: false
      parameter 'filters[appeal][]',                   'Filter by Appeal; Accepts multiple parameters, with value "no_appeals", or an appeal ID',             required: false
      parameter 'filters[church][]',                   'Filter by Church; Accepts multiple parameters, with value "none", or a church name',                  required: false
      parameter 'filters[city][]',                     'Filter by City; Accepts multiple parameters, with value "none", or a city name',                      required: false
      parameter 'filters[contact_info_addr]',          'Filter by Address; Accepts values "Yes", or "No"',                                                    required: false
      parameter 'filters[contact_info_email]',         'Filter by Email; Accepts values "Yes", or "No"',                                                      required: false
      parameter 'filters[contact_info_facebook]',      'Filter by Facebook Profile; Accepts values "Yes", or "No"',                                           required: false
      parameter 'filters[contact_info_mobile]',        'Filter by Mobile Phone; Accepts values "Yes", or "No"',                                               required: false
      parameter 'filters[contact_info_phone]',         'Filter by Home Phone; Accepts values "Yes", or "No"',                                                 required: false
      parameter 'filters[contact_info_work_phone]',    'Filter by Work Phone; Accepts values "Yes", or "No"',                                                 required: false
      parameter 'filters[contact_type][]',             'Filter by Type; Accepts multiple parameters, with values "person", and "company"',                    required: false
      parameter 'filters[country][]',                  'Filter by Country; Accepts multiple parameters, with values "none", or a country',                    required: false
      parameter 'filters[donation][]',                 'Filter by Gift Options; Accepts multiple parameters, with values "none", "one", "first", and "last"', required: false
      parameter 'filters[donation_amount][]',          'Filter by Exact Gift Amount; Accepts multiple parameters, with values like "9.99"',                   required: false
      parameter 'filters[donation_amount_range][min]', 'Filter by Gift Amount Range, Minimum; Accepts values like "9.99"',                                    required: false
      parameter 'filters[donation_amount_range][max]', 'Filter by Gift Amount Range, Maximum; Accepts values like "9.99"',                                    required: false
      parameter 'filters[donation_date]',              'Filter by Gift Date; Accepts date range with text value like "MM/DD/YYYY - MM/DD/YYYY"',              required: false
      parameter 'filters[likely][]',                   'Filter by Likely To Give; Accepts multiple parameters, with values "none", "Least Likely", "Likely", '\
                                                       'and "Most Likely"',                                                                                   required: false
      parameter 'filters[locale][]',                   'Filter by Language; Accepts multiple parameters,',                                                    required: false
      parameter 'filters[metro_area][]',               'Filter by Metro Area; Accepts multiple parameters, with values "none", or a metro area name',         required: false
      parameter 'filters[newsletter]',                 'Filter by Newsletter Recipients; Accepts values "none", "all", "address", "email", and "both"',       required: false
      parameter 'filters[pledge_amount][]',            'Filter by Commitment Amount; Accepts multiple parameters, with values like "100.0"',                  required: false
      parameter 'filters[pledge_currency][]',          'Filter by Commitment Currency; Accepts multiple parameters, with values like "USD"',                  required: false
      parameter 'filters[pledge_frequencies][]',       'Filter by Commitment Frequency; Accepts multiple parameters, with numeric values like "0.23076923076923" (Weekly), '\
                                                       '"0.46153846153846" (Every 2 Weeks), "1.0" (Monthly), "2.0" (Every 2 Months), "3.0", "4.0", "6.0", "12.0" (Yearly), '\
                                                       'and "24.0" (Every 2 Years)',                                                                          required: false
      parameter 'filters[pledge_late_by]',             'Filter by Late By; Accepts values "", "0_30" (Less than 30 days late), "30_60" (More than 30 days late), '\
                                                       '"60_90" (More than 60 days late), or "90" (More than 90 days late)',                                  required: false
      parameter 'filters[pledge_received]',            'Filter by Commitment Received; Accepts values "true", or "false"',                                    required: false
      parameter 'filters[referrer][]',                 'Filter by Referrer; Accepts multiple parameters, with values "none", "any", or a Contact ID',         required: false
      parameter 'filters[region][]',                   'Filter by Region; Accepts multiple parameters, with values "none", or a region name',                 required: false
      parameter 'filters[related_task_action][]',      'Filter by Action; Accepts multiple parameters, with values "null", or an activity type like "Call"',  required: false
      parameter 'filters[state][]',                    'Filter by State; Accepts multiple parameters, with values "none", or a state',                        required: false
      parameter 'filters[status][]',                   'Filter by Status; Accepts multiple parameters, with values "active", "hidden", "null", "Never Contacted", '\
                                                       '"Ask in Future", "Cultivate Relationship", "Contact for Appointment", "Appointment Scheduled", '\
                                                       '"Call for Decision", "Partner - Financial", "Partner - Special", "Partner - Pray", "Not Interested", '\
                                                       '"Unresponsive", "Never Ask", "Research Abandoned", and "Expired Referral"',                           required: false
      parameter 'filters[task_due_date]',              'Filter by Due Date; Accepts date range with text value like "MM/DD/YYYY - MM/DD/YYYY"',               required: false
      parameter 'filters[timezone][]',                 'Filter by Timezone; Accepts multiple parameters,',                                                    required: false

      response_field :data, 'Data', 'Type' => 'Array[Object]'

      example 'Contact [LIST]', document: :entities do
        explanation 'List of Contacts'
        do_request
        check_collection_resource(1, additional_keys)
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',     'Account List ID',                                    'Type' => 'String'
        parameter 'church_name',         'Church Name',                                        'Type' => 'String'
        parameter 'direct_deposit',      'Direct Deposit',                                     'Type' => 'Boolean'
        parameter 'envelope_greeting',   'Envelope Greeting',                                  'Type' => 'String'
        parameter 'full_name',           'Full Name',                                          'Type' => 'String'
        parameter 'greeting',            'Greeting',                                           'Type' => 'String'
        parameter 'likely_to_give',      'Likely To Give',                                     'Type' => 'String'
        parameter 'locale',              'Locale',                                             'Type' => 'String'
        parameter 'magazine',            'Magazine',                                           'Type' => 'String'
        parameter 'name',                'Contact Name',                                       'Type' => 'String'
        parameter 'next_ask',            'Next Ask',                                           'Type' => 'String'
        parameter 'no_appeals',          'No Appeals',                                         'Type' => 'String'
        parameter 'not_duplicated_with', 'IDs of contacts that are known to not be duplicates', 'Type' => 'String'
        parameter 'notes',               'Notes',                                              'Type' => 'String'
        parameter 'pledge_amount',       'Pledge Amount',                                      'Type' => 'Number'
        parameter 'pledge_currency',     'Pledge Currency',                                    'Type' => 'String'
        parameter 'pledge_frequency',    'Pledge Frequency',                                   'Type' => 'String'
        parameter 'pledge_received',     'Pledge Received',                                    'Type' => 'Boolean'
        parameter 'pledge_start_date',   'Pledge Start Date',                                  'Type' => 'String'
        parameter 'primary_person_id',   'Primary Person ID',                                  'Type' => 'String'
        parameter 'send_newsletter',     'Send Newsletter',                                    'Type' => 'String'
        parameter 'status',              'Status',                                             'Type' => 'String'
        parameter 'tag_list',            'Tag List',                                           'Type' => 'String'
        parameter 'timezone',            'Time Zone',                                          'Type' => 'String'
        parameter 'website',             'Website',                                            'Type' => 'String'
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
        response_field 'updated_in_db_at',        'Updated In Db At',        'Type' => 'String'
      end

      example 'Contact [GET]', document: :entities do
        explanation 'The Contact with the given ID'
        do_request
        check_resource(additional_keys)
        expect(resource_object['name']).to eq contact.name
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/contacts/:id' do
      parameter :id, 'ID of the Contact', required: true
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id',     'Account List ID',                                    'Type' => 'String'
        parameter 'church_name',         'Church Name',                                        'Type' => 'String'
        parameter 'direct_deposit',      'Direct Deposit',                                     'Type' => 'Boolean'
        parameter 'envelope_greeting',   'Envelope Greeting',                                  'Type' => 'String'
        parameter 'full_name',           'Full Name',                                          'Type' => 'String'
        parameter 'greeting',            'Greeting',                                           'Type' => 'String'
        parameter 'likely_to_give',      'Likely To Give',                                     'Type' => 'String'
        parameter 'locale',              'Locale',                                             'Type' => 'String'
        parameter 'magazine',            'Magazine',                                           'Type' => 'String'
        parameter 'name',                'Contact Name',                                       'Type' => 'String'
        parameter 'next_ask',            'Next Ask',                                           'Type' => 'String'
        parameter 'no_appeals',          'No Appeals',                                         'Type' => 'String'
        parameter 'not_duplicated_with', 'IDs of contacts that are known to not be duplicates', 'Type' => 'String'
        parameter 'notes',               'Notes',                                              'Type' => 'String'
        parameter 'pledge_amount',       'Pledge Amount',                                      'Type' => 'Number'
        parameter 'pledge_currency',     'Pledge Currency',                                    'Type' => 'String'
        parameter 'pledge_frequency',    'Pledge Frequency',                                   'Type' => 'String'
        parameter 'pledge_received',     'Pledge Received',                                    'Type' => 'Boolean'
        parameter 'pledge_start_date',   'Pledge Start Date',                                  'Type' => 'String'
        parameter 'primary_person_id',   'Primary Person ID',                                  'Type' => 'String'
        parameter 'send_newsletter',     'Send Newsletter',                                    'Type' => 'String'
        parameter 'status',              'Status',                                             'Type' => 'String'
        parameter 'tag_list',            'Tag List',                                           'Type' => 'String'
        parameter 'timezone',            'Time Zone',                                          'Type' => 'String'
        parameter 'website',             'Website',                                            'Type' => 'String'
      end

      example 'Contact [UPDATE]', document: :entities do
        explanation 'Update the Contact with the given ID'
        do_request data: form_data
        expect(resource_object['name']).to eq new_contact['name']
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/contacts/bulk' do
      parameter 'data', 'Array of Contacts that have to be updated'

      with_options scope: :data do
        parameter 'id', 'Each member of the array must contain the id of the contact being updated'
        parameter 'attributes', 'Each member of the array must contain an object with the attributes that must be updated'
      end

      response_field 'data',
                     'List of Contact objects that have been successfully updated and list of errors related to Contact objects that were not updated successfully',
                     'Type' => 'Array[Object]'

      example 'Contact [UPDATE][BULK]', document: :entities do
        explanation 'Bulk Update a list of Contacts with an array of objects containing the ID and updated attributes'
        do_request data: bulk_update_form_data
        expect(json_response.first['data']['attributes']['name']).to eq new_contact['name']
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
