require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Twitter Accounts' do
  let(:resource_type) { 'person-twitter-accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let(:contact_id) { contact.id }
  let!(:person) { create(:person) }
  let(:person_id) { person.id }
  let!(:twitter_accounts) { create_list(:twitter_account, 2, person: person) }
  let(:twitter_account) { twitter_accounts.first }
  let(:id) { twitter_account.id }
  let(:new_twitter_account) { build(:twitter_account).attributes }
  let(:form_data) { build_data(new_twitter_account) }
  let(:expected_attribute_keys) do
    %w(created-at
       primary
       remote-id
       screen-name
       updated-at)
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/twitter-accounts' do
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      response_field 'data',                    'Data', 'Type' => 'Array[Object]'
      example_request 'list twitter accounts of person' do
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    get '/api/v2/contacts/:contact_id/people/:person_id/twitter-accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created-at',              'Created At', 'Type' => 'String'
        response_field 'primary',                 'Primary', 'Type' => 'Boolean'
        response_field 'remote-id',               'Remote ID', 'Type' => 'Number'
        response_field 'screen-name',             'Screen Name', 'Type' => 'String'
        response_field 'updated-at',              'Updated At', 'Type' => 'String'
      end
      example_request 'get twitter account' do
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
    post '/api/v2/contacts/:contact_id/people/:person_id/twitter-accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'primary',                      'Primary'
        parameter 'remote-id',                    'Remote ID'
        parameter 'screen-name',                  'Screen Name'
      end
      example 'create twitter account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
    put '/api/v2/contacts/:contact_id/people/:person_id/twitter-accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'primary',                      'Primary'
        parameter 'remote-id',                    'Remote ID'
        parameter 'screen-name',                  'Screen Name'
      end
      example 'update twitter account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end
    delete '/api/v2/contacts/:contact_id/people/:person_id/twitter-accounts/:id' do
      parameter 'contact_id',                   'Contact ID', required: true
      parameter 'person-id',                    'Person ID', required: true
      example_request 'delete twitter account' do
        expect(response_status).to eq 200
      end
    end
  end
end