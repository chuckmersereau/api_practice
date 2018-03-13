require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'People > Duplicates' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:people, :duplicates])
  # This is the scope in how these endpoints will be organized in the
  # generated documentation.
  #
  # :entities should be used for "top level" resources, and the top level
  # resources should be used for nested resources.
  #
  # Ex: Api > v2 > Contacts                   - :entities would be the scope
  # Ex: Api > v2 > Contacts > Email Addresses - :contacts would be the scope
  # documentation_scope = :contacts_api_duplicates

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'duplicate_record_pairs' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:duplicate_record_pair) { create(:duplicate_people_pair) }
  let(:resource) { duplicate_record_pair }
  let(:account_list) { resource.account_list }
  let(:user) { create(:user).tap { |user| account_list.users << user } }
  let(:id) { resource.id }

  # List your expected resource keys vertically here (alphabetical please!)
  let(:expected_attribute_keys) do
    %w(
      created_at
      ignore
      reason
      updated_at
      updated_in_db_at
    )
  end

  # List out any additional attribute keys that will be alongside
  # the attributes of the resources.
  #
  # Remove if not needed.
  let(:additional_attribute_keys) do
    %w(
      relationships
    )
  end

  let(:form_data) do
    build_data({
                 ignore: true,
                 updated_in_db_at: resource.updated_at
               }, relationships: relationships)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      }
    }
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/people/duplicates' do
      doc_helper.insert_documentation_for(action: :index, context: self)

      example doc_helper.title_for(:index), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:index)
        do_request

        check_collection_resource(1, additional_attribute_keys)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/people/duplicates/:id' do
      doc_helper.insert_documentation_for(action: :show, context: self)

      example doc_helper.title_for(:show), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:show)
        do_request

        check_resource(['relationships'], additional_attribute_keys)
        expect(resource_object['reason']).to eq resource.reason
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/contacts/people/duplicates/:id' do
      doc_helper.insert_documentation_for(action: :update, context: self)

      example doc_helper.title_for(:update), document: doc_helper.document_scope do
        explanation doc_helper.description_for(:update)
        do_request data: form_data

        expect(response_status).to eq(200), invalid_status_detail
        expect(resource_object['ignore']).to eq(true)
      end
    end
  end
end
