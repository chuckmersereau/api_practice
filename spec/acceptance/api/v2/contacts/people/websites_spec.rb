require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Websites' do
  let(:resource_type) { 'person-websites' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let(:contact_id) { contact.id }
  let!(:person) { create(:person) }
  let(:person_id) { person.id }
  let!(:websites) { create_list(:website, 2, person: person) }
  let(:website) { websites.first }
  let(:id) { website.id }
  let(:new_website) { build(:website).attributes }
  let(:form_data) { build_data(new_website) }
  let(:expected_attribute_keys) do
    %w(created-at
       primary
       updated-at
       url)
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/websites' do
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      response_field 'data',                    'Data', 'Type' => 'Array[Object]'
      example_request 'list facebook websites of person' do
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/websites/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'primary',                 'Primary', 'Type' => 'Boolean'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
        response_field 'url',                     'Url', 'Type' => 'String'
      end
      example_request 'get website' do
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/websites' do
      with_options scope: [:data, :attributes] do
        parameter 'primary',                      'Primary'
        parameter 'url',                          'Url'
      end
      example 'create website' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
    put '/api/v2/contacts/:contact_id/people/:person_id/websites/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'primary',                      'Primary'
        parameter 'url',                          'Url'
      end
      example 'update website' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
    delete '/api/v2/contacts/:contact_id/people/:person_id/websites/:id' do
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      example_request 'delete website' do
        expect(response_status).to eq 200
      end
    end
  end
end
