require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Duplicates' do
  include_context :json_headers

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'person_duplicates' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:person1) { create(:person, first_name: 'John', last_name: 'Doe') }
  let(:person2) { create(:person, first_name: 'john', last_name: 'doe') }
  let(:contact) { create(:contact, name: 'Doe, John', account_list: account_list) }

  let(:resource) do
    Person::Duplicate.new(
      person: person1,
      dup_person: person2,
      shared_contact: contact
    )
  end

  let(:id) { resource.id }

  # List your expected resource keys vertically here (alphabetical please!)
  let(:resource_attributes) do
    []
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

  # This is the scope in how these endpoints will be organized in the
  # generated documentation.
  #
  # :entities should be used for "top level" resources, and the top level
  # resources should be used for nested resources.
  #
  # Ex: Api > v2 > Contacts                   - :entities would be the scope
  # Ex: Api > v2 > Contacts > Email Addresses - :contacts would be the scope
  document = :people

  before do
    contact.people << person1
    contact.people << person2
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/contacts/people/duplicates' do
      parameter 'filters[account_list_id]', 'Filter by Account List; Accepts Account List ID',                                                     required: false
      
      example 'Duplicate [LIST]', document: document do
        explanation 'List of Duplicates'
        do_request

        check_collection_resource(1, additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # destroy
    delete '/api/v2/contacts/people/duplicates/:id' do
      example 'Duplicate [DELETE]', document: document do
        explanation 'Mark the two associated people as not duplicates'
        do_request

        expect(response_status).to eq 204
      end
    end
  end
end
