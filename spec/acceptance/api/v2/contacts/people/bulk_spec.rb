require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'People Bulk' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: :people)

  let!(:account_list)  { user.account_lists.order(:created_at).first }

  let!(:contact)       { create(:contact, account_list: account_list) }
  let!(:person_one)    { create(:person, contacts: [contact]) }
  let!(:person_two)    { create(:person, contacts: [contact]) }

  let!(:resource_type) { 'people' }
  let!(:user)          { create(:user_with_account) }

  let(:new_person_attributes) do
    attributes_for(:person)
      .merge(updated_in_db_at: person_one.updated_at)
  end

  let(:contacts_relationship) do
    {
      contacts: {
        data: [
          type: 'contacts',
          id: contact.id
        ]
      }
    }
  end

  let(:bulk_create_form_data) do
    [
      {
        data: {
          type: resource_type,
          id: SecureRandom.uuid,
          attributes: new_person_attributes,
          relationships: contacts_relationship
        }
      }
    ]
  end

  let(:bulk_update_form_data) do
    [
      {
        data: {
          type: resource_type,
          id: person_one.id,
          attributes: new_person_attributes
        }
      }
    ]
  end

  context 'authorized user' do
    before { api_login(user) }

    post '/api/v2/contacts/people/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_create, context: self)

      example doc_helper.title_for(:bulk_create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_create)
        do_request data: bulk_create_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['name']).to eq new_person_attributes[:name]
      end
    end

    put '/api/v2/contacts/people/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_update, context: self)

      example doc_helper.title_for(:bulk_update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_update)
        do_request data: bulk_update_form_data

        expect(response_status).to eq(200)
        expect(json_response.first['data']['attributes']['name']).to eq new_person_attributes[:name]
      end
    end

    delete '/api/v2/contacts/people/bulk' do
      doc_helper.insert_documentation_for(action: :bulk_delete, context: self)

      example doc_helper.title_for(:bulk_delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:bulk_delete)
        do_request data: [
          { data: { type: resource_type, id: person_one.id } },
          { data: { type: resource_type, id: person_two.id } }
        ]

        expect(response_status).to eq(200)
        expect(json_response.size).to eq(2)
        expect(json_response.collect { |hash| hash.dig('data', 'id') }).to match_array([person_one.id, person_two.id])
      end
    end
  end
end
