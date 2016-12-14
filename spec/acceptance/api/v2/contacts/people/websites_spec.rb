require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Websites' do
  include_context :json_headers

  let(:resource_type) { 'websites' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let!(:person)   { create(:person) }
  let(:person_id) { person.uuid }

  let!(:websites) { create_list(:website, 2, person: person) }
  let(:website)   { websites.first }
  let(:id)        { website.uuid }

  let(:new_website) { build(:website).attributes.merge(person_id: person.uuid) }
  let(:form_data)   { build_data(new_website) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      primary
      updated_at
      url
    )
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/websites' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID', required: true
      response_field 'data',  'Data', 'Type' => 'Array[Object]'

      example 'Person / Website [LIST]', document: :contacts do
        explanation 'List of Websites associated to the Person'
        do_request
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/websites/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at', 'Created At', 'Type' => 'String'
        response_field 'primary',    'Primary',    'Type' => 'Boolean'
        response_field 'updated_at', 'Updated At', 'Type' => 'String'
        response_field 'url',        'Url',        'Type' => 'String'
      end

      example 'Person / Website [GET]', document: :contacts do
        explanation 'The Person\'s Website with the given ID'
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/websites' do
      with_options scope: [:data, :attributes] do
        parameter 'primary', 'Primary'
        parameter 'url',     'Url'
      end

      example 'Person / Website [CREATE]', document: :contacts do
        explanation 'Create a Website associated with the Person'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/websites/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'primary', 'Primary'
        parameter 'url',     'Url'
      end

      example 'Person / Website [UPDATE]', document: :contacts do
        explanation 'Update the Person\'s Website with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/websites/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example 'Person / Website [DELETE]', document: :contacts do
        explanation 'Delete the Person\'s Website with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
