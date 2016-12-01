require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Facebook Accounts' do
  let(:resource_type) { 'person-facebook-accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let(:contact_id) { contact.id }
  let!(:person) { create(:person) }
  let(:person_id) { person.id }
  let!(:facebook_accounts) { create_list(:facebook_account, 2, person: person) }
  let(:facebook_account) { facebook_accounts.first }
  let(:id) { facebook_account.id }
  let(:new_facebook_account) { build(:facebook_account).attributes }
  let(:form_data) { build_data(new_facebook_account) }
  let(:expected_attribute_keys) do
    %w(created-at
       first-name
       last-name
       remote-id
       updated-at
       username)
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/facebook-accounts' do
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      response_field 'data',                    'Data', 'Type' => 'Array[Object]'
      example_request 'list facebook accounts of person' do
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/facebook-accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'first-name',              'First Name', 'Type' => 'String'
        response_field 'last-name',               'Last name', 'Type' => 'Number'
        response_field 'remote-id',               'Remote ID', 'Type' => 'Number'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
        response_field 'username',                'Username', 'Type' => 'String'
      end
      example_request 'get facebook account' do
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/facebook-accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'first-name',                   'First Name'
        parameter 'last-name',                    'Last Name'
        parameter 'remote-id',                    'Remote ID'
        parameter 'username',                     'Username'
      end
      example 'create facebook account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
    put '/api/v2/contacts/:contact_id/people/:person_id/facebook-accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'first-name',                   'First Name'
        parameter 'last-name',                    'Last Name'
        parameter 'remote-id',                    'Remote ID'
        parameter 'username',                     'Username'
      end
      example 'update facebook account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
    delete '/api/v2/contacts/:contact_id/people/:person_id/facebook-accounts/:id' do
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      example_request 'delete facebook account' do
        expect(response_status).to eq 200
      end
    end
  end
end