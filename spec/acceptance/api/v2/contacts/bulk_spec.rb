require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts Bulk' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :contacts)

  let!(:account_list)    { user.account_lists.first }
  let!(:contact_one)     { create(:contact, account_list: account_list) }
  let!(:contact_two)     { create(:contact, account_list: account_list) }
  let!(:resource_type)   { 'contacts' }
  let!(:user)            { create(:user_with_account) }
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
      ).merge(updated_in_db_at: contact_one.updated_at)
  end

  let(:account_list_relationship) do
    {
      account_list: {
        data: {
          id: account_list.uuid,
          type: 'account_lists'
        }
      }
    }
  end

  let(:bulk_create_form_data) do
    [{ data: { type: resource_type, id: SecureRandom.uuid, attributes: new_contact, relationships: account_list_relationship } }]
  end

  let(:bulk_update_form_data) do
    [{ data: { type: resource_type, id: contact_one.uuid, attributes: new_contact } }]
  end

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/contacts/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_create, context: self)

      example doc_helper.title_for(:bulk_create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_create)
        do_request data: bulk_create_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['name']).to eq new_contact[:name]
      end
    end

    put '/api/v2/contacts/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_update, context: self)

      example doc_helper.title_for(:bulk_update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_update)
        do_request data: bulk_update_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['name']).to eq new_contact[:name]
      end
    end

    delete '/api/v2/contacts/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_delete, context: self)

      example doc_helper.title_for(:bulk_delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_delete)
        do_request data: [
          { data: { type: resource_type, id: contact_one.uuid } },
          { data: { type: resource_type, id: contact_two.uuid } }
        ]

        expect(response_status).to eq(200)
        expect(json_response.size).to eq(2)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([contact_one.uuid, contact_two.uuid])
      end
    end
  end
end
