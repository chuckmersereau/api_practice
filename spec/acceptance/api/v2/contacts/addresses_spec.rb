require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Addresses' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:contacts, :addresses])

  let!(:user) { create(:user_with_full_account) }
  let(:resource_type) { 'addresses' }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.uuid }

  let!(:address) { create(:address, addressable: contact) }
  let(:id) { address.uuid }

  let(:new_address) do
    attributes_for(:address, addressable: contact)
      .reject { |key| key.to_s.end_with?('_id', '_at') }
      .merge(updated_in_db_at: address.updated_at)
  end

  let(:form_data) { build_data(new_address) }

  let(:resource_attributes) do
    %w(
      city
      country
      created_at
      end_date
      geo
      historic
      location
      metro_area
      postal_code
      primary_mailing_address
      region
      remote_id
      seasonal
      source
      start_date
      state
      street
      updated_at
      updated_in_db_at
      valid_values
    )
  end

  let(:resource_associations) do
    %w(
      source_donor_account
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/addresses' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        check_collection_resource 1, %w(relationships)
      end
    end

    get '/api/v2/contacts/:contact_id/addresses/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        expect(response_status).to eq(200), invalid_status_detail
        check_resource %w(relationships)
      end
    end

    post '/api/v2/contacts/:contact_id/addresses' do
      doc_helper.insert_documentation_for(action: :create, context: self)
      example doc_helper.title_for(:create), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:create)

        do_request data: form_data

        expect(response_status).to eq(201), invalid_status_detail
        expect(resource_object['street']).to(be_present) && eq(new_address['street'])
      end
    end

    put '/api/v2/contacts/:contact_id/addresses/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data

        expect(response_status).to eq(200), invalid_status_detail
        expect(resource_object['street']).to(be_present) && eq(new_address['street'])
      end
    end

    delete '/api/v2/contacts/:contact_id/addresses/:id' do
      doc_helper.insert_documentation_for(action: :delete, context: self)

      example doc_helper.title_for(:delete), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:delete)
        do_request
        expect(response_status).to eq(204)
      end
    end
  end
end
