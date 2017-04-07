require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :contacts)

  let(:resource_type) { 'contacts' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list)    { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact) { create(:contact, account_list: account_list) }
  let(:id)       { contact.uuid }

  let(:new_contact) do
    attributes_for(:contact)
      .except(
        :first_donation_date,
        :last_activity,
        :last_appointment,
        :last_donation_date,
        :last_letter,
        :last_phone_call,
        :last_pre_call,
        :last_thank,
        :late_at,
        :notes_saved_at,
        :pls_id,
        :prayer_letters_id,
        :prayer_letters_params,
        :tnt_id,
        :total_donations,
        :uncompleted_tasks_count
      ).merge(updated_in_db_at: contact.updated_at)
  end

  let(:form_data) do
    build_data(new_contact, relationships: relationships)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.uuid
        }
      }
    }
  end

  let(:additional_keys) { ['relationships'] }

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
      website
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
      primary_or_first_person
      primary_person
      tasks
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      with_options scope: :sort do
        parameter :created_at, 'Sort By CreatedAt'
        parameter :name,       'Sort By Name'
        parameter :updated_at, 'Sort By UpdatedAt'
      end

      parameter 'filter[account_list_id]',            'Filter by Account List; Accepts Account List ID',                                                     required: false
      parameter 'filter[address_historic]',           'Filter by Address Historic; Accepts values "true", or "false"',                                       required: false
      parameter 'filter[address_valid]',              %(Filter by Address Invalid; A Contact's Address is invalid if \
                                                         the Address's valid attribute is set to false, or if the Contact has \
                                                         multiple Addresses marked as primary; Accepts value "false"), required: false
      parameter 'filter[appeal][]',                   'Filter by Appeal; Accepts multiple parameters, with value "no_appeals", or an appeal ID',             required: false
      parameter 'filter[church][]',                   'Filter by Church; Accepts multiple parameters, with value "none", or a church name',                  required: false
      parameter 'filter[city][]',                     'Filter by City; Accepts multiple parameters, with value "none", or a city name',                      required: false
      parameter 'filter[contact_info_addr]',          'Filter by Address; Accepts values "Yes", or "No"',                                                    required: false
      parameter 'filter[contact_info_email]',         'Filter by Email; Accepts values "Yes", or "No"',                                                      required: false
      parameter 'filter[contact_info_facebook]',      'Filter by Facebook Profile; Accepts values "Yes", or "No"',                                           required: false
      parameter 'filter[contact_info_mobile]',        'Filter by Mobile Phone; Accepts values "Yes", or "No"',                                               required: false
      parameter 'filter[contact_info_phone]',         'Filter by Home Phone; Accepts values "Yes", or "No"',                                                 required: false
      parameter 'filter[contact_info_work_phone]',    'Filter by Work Phone; Accepts values "Yes", or "No"',                                                 required: false
      parameter 'filter[contact_type][]',             'Filter by Type; Accepts multiple parameters, with values "person", and "company"',                    required: false
      parameter 'filter[country][]',                  'Filter by Country; Accepts multiple parameters, with values "none", or a country',                    required: false
      parameter 'filter[donation][]',                 'Filter by Gift Options; Accepts multiple parameters, with values "none", "one", "first", and "last"', required: false
      parameter 'filter[donation_amount][]',          'Filter by Exact Gift Amount; Accepts multiple parameters, with values like "9.99"',                   required: false
      parameter 'filter[donation_amount_range][min]', 'Filter by Gift Amount Range, Minimum; Accepts values like "9.99"',                                    required: false
      parameter 'filter[donation_amount_range][max]', 'Filter by Gift Amount Range, Maximum; Accepts values like "9.99"',                                    required: false
      parameter 'filter[donation_date]',              'Filter by Gift Date; Accepts date range with text value like "MM/DD/YYYY - MM/DD/YYYY"',              required: false
      parameter 'filter[likely][]',                   'Filter by Likely To Give; Accepts multiple parameters, with values "none", "Least Likely", "Likely", '\
                                                       'and "Most Likely"', required: false
      parameter 'filter[locale][]',                   'Filter by Language; Accepts multiple parameters,',                                                    required: false
      parameter 'filter[metro_area][]',               'Filter by Metro Area; Accepts multiple parameters, with values "none", or a metro area name',         required: false
      parameter 'filter[newsletter]',                 'Filter by Newsletter Recipients; Accepts values "none", "all", "address", "email", and "both"',       required: false
      parameter 'filter[pledge_amount][]',            'Filter by Commitment Amount; Accepts multiple parameters, with values like "100.0"',                  required: false
      parameter 'filter[pledge_currency][]',          'Filter by Commitment Currency; Accepts multiple parameters, with values like "USD"',                  required: false
      parameter 'filter[pledge_frequencies][]',       'Filter by Commitment Frequency; Accepts multiple parameters, with numeric values like "0.23076923076923" (Weekly), '\
                                                       '"0.46153846153846" (Every 2 Weeks), "1.0" (Monthly), "2.0" (Every 2 Months), "3.0", "4.0", "6.0", "12.0" (Yearly), '\
                                                       'and "24.0" (Every 2 Years)',                                                                          required: false
      parameter 'filter[pledge_late_by]',             'Filter by Late By; Accepts values "", "0_30" (Less than 30 days late), "30_60" (More than 30 days late), '\
                                                       '"60_90" (More than 60 days late), or "90" (More than 90 days late)',                                  required: false
      parameter 'filter[pledge_received]',            'Filter by Commitment Received; Accepts values "true", or "false"',                                    required: false
      parameter 'filter[referrer][]',                 'Filter by Referrer; Accepts multiple parameters, with values "none", "any", or a Contact ID',         required: false
      parameter 'filter[region][]',                   'Filter by Region; Accepts multiple parameters, with values "none", or a region name',                 required: false
      parameter 'filter[related_task_action][]',      'Filter by Action; Accepts multiple parameters, with values "null", or an activity type like "Call"',  required: false
      parameter 'filter[state][]',                    'Filter by State; Accepts multiple parameters, with values "none", or a state',                        required: false
      parameter 'filter[status][]',                   'Filter by Status; Accepts multiple parameters, with values "active", "hidden", "null", "Never Contacted", '\
                                                       '"Ask in Future", "Cultivate Relationship", "Contact for Appointment", "Appointment Scheduled", '\
                                                       '"Call for Decision", "Partner - Financial", "Partner - Special", "Partner - Pray", "Not Interested", '\
                                                       '"Unresponsive", "Never Ask", "Research Abandoned", and "Expired Referral"', required: false
      parameter 'filter[status_valid]',               'Filter by Status Valid; Accepts values "true", or "false"',                                           required: false
      parameter 'filter[task_due_date]',              'Filter by Due Date; Accepts date range with text value like "MM/DD/YYYY - MM/DD/YYYY"',               required: false
      parameter 'filter[timezone][]',                 'Filter by Timezone; Accepts multiple parameters,',                                                    required: false

      response_field :data, 'Data', 'Type' => 'Array[Object]'

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        check_collection_resource(1, additional_keys)
      end
    end

    get '/api/v2/contacts/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)
      with_options scope: :relationships do
        response_field :primary_person,          'Primary Person Object',   'Type' => 'Object'
        response_field :primary_or_first_person, 'Primary Or First Person', 'Type' => 'Object'
      end

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(additional_keys)
        expect(resource_object['name']).to eq contact.name
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts' do
      doc_helper.insert_documentation_for(action: :create, context: self)

      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)
        do_request data: form_data

        expect(response_status).to eq(201), invalid_status_detail
        expect(resource_object['name']).to eq new_contact[:name]
      end
    end

    put '/api/v2/contacts/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data

        expect(response_status).to eq(200), invalid_status_detail
        expect(resource_object['name']).to eq new_contact[:name]
      end
    end

    delete '/api/v2/contacts/:id' do
      doc_helper.insert_documentation_for(action: :delete, context: self)

      example doc_helper.title_for(:delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:delete)
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
