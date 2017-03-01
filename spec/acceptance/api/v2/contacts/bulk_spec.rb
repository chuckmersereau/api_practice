require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts Bulk' do
  include_context :json_headers
  documentation_scope = :entities_contacts

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
      parameter 'data', 'Array of Contacts that have to be created'

      with_options scope: :data do
        parameter 'id',         'Each member of the array must contain a client generated id of the contact being created', 'Type' =>  'String'
        parameter 'type',       "Each member of the array must contain the type 'contacts'",                                'Type' =>  'String'
        parameter 'attributes', 'Each member of the array must contain an object with the attributes that must be created', 'Type' =>  'Object'
      end

      response_field 'data',
                     'List of Contact objects that have been successfully created and list of errors related to Contact objects that were not updated successfully',
                     'Type' => 'Array[Object]'

      example 'Contact [CREATE] [BULK]', document: documentation_scope do
        explanation 'Bulk Create a list of Contacts with an array of objects containing the attributes of each contact'
        do_request data: bulk_create_form_data
        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['name']).to eq new_contact[:name]
      end
    end

    put '/api/v2/contacts/bulk' do
      parameter 'data', 'Array of Contacts that have to be updated'

      with_options scope: :data do
        parameter 'id',         'Each member of the array must contain the id of the contact being updated',                'Type' =>  'String'
        parameter 'type',       "Each member of the array must contain the type 'contacts'",                                'Type' =>  'String'
        parameter 'attributes', 'Each member of the array must contain an object with the attributes that must be updated', 'Type' =>  'Object'
      end

      response_field 'data',
                     'List of Contact objects that have been successfully updated and list of errors related to Contact objects that were not updated successfully',
                     'Type' => 'Array[Object]'

      example 'Contact [UPDATE] [BULK]', document: documentation_scope do
        explanation 'Bulk Update a list of Contacts with an array of objects containing the ID and updated attributes'
        do_request data: bulk_update_form_data
        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['name']).to eq new_contact[:name]
      end
    end

    delete '/api/v2/contacts/bulk' do
      with_options scope: :data do
        parameter :id, 'Each member of the array must contain the id of the contact being deleted'
      end

      example 'Contact [DELETE] [BULK]', document: documentation_scope do
        explanation 'Bulk delete Contacts with the given IDs'
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
