require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > People > Email Addresses' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:people, :email_addresses])

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'email_addresses' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user)          { create(:user_with_account) }
  let(:account_list)  { user.account_lists.order(:created_at).first }

  let(:contact)       { create(:contact, account_list: account_list) }
  let(:contact_id)    { contact.id }

  let(:person)        { create(:person, contacts: [contact]) }
  let(:person_id)     { person.id }

  let!(:email_address) { create(:email_address, person: person) }
  let(:id)             { email_address.id }

  let(:form_data) do
    build_data(
      attributes
        .reject { |key| key.to_s.end_with?('_id') }
        .merge(updated_in_db_at: email_address.updated_at)
    )
  end

  let(:expected_attribute_keys) do
    # list your expected resource keys vertically here (alphabetical please!)
    %w(
      created_at
      email
      historic
      location
      primary
      source
      updated_at
      updated_in_db_at
      valid_values
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/contacts/:contact_id/people/:person_id/email_addresses' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      before { email_address }

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource(1)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq email_address.email
        expect(response_status).to eq 200
      end
    end

    # show
    get '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource
        expect(resource_object.keys.sort).to eq expected_attribute_keys
        expect(resource_object['email']).to  eq email_address.email
        expect(response_status).to eq 200
      end
    end

    # create
    post '/api/v2/contacts/:contact_id/people/:person_id/email_addresses' do
      doc_helper.insert_documentation_for(action: :create, context: self)

      let(:attributes) { attributes_for(:email_address).merge(person_id: person.id) }

      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)
        do_request data: form_data

        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq attributes[:email]
        expect(response_status).to eq 201
      end
    end

    # update
    put '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      let(:attributes) { email_address.attributes.merge(person_id: person.id) }

      before { attributes.merge!(email: 'new-email@example.com') }

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data

        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq 'new-email@example.com'
        expect(response_status).to eq 200
      end
    end

    # destroy
    delete '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      doc_helper.insert_documentation_for(action: :delete, context: self)

      example doc_helper.title_for(:delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:delete)
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
