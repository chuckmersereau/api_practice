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
      primary_person
      tasks
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        check_collection_resource(1, additional_keys)
      end
    end

    get '/api/v2/contacts/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

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
