require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Twitter Accounts' do
  include_context :json_headers

  let(:resource_type) { 'person_twitter_accounts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let!(:person)   { create(:person) }
  let(:person_id) { person.uuid }

  let!(:twitter_accounts) { create_list(:twitter_account, 2, person: person) }
  let(:twitter_account)   { twitter_accounts.first }
  let(:id)                { twitter_account.uuid }

  let(:new_twitter_account) { build(:twitter_account).attributes.except('person_id') }
  let(:form_data)           { build_data(new_twitter_account) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      primary
      remote_id
      screen_name
      updated_at
    )
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID', required: true
      response_field 'data',  'Data', 'Type' => 'Array[Object]'

      example 'Person / Twitter Account [LIST]', document: :contacts do
        explanation 'List of Twitter Accounts associated to the Person'
        do_request
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',  'Created At',  'Type' => 'String'
        response_field 'primary',     'Primary',     'Type' => 'Boolean'
        response_field 'remote_id',   'Remote ID',   'Type' => 'Number'
        response_field 'screen_name', 'Screen Name', 'Type' => 'String'
        response_field 'updated_at',  'Updated At',  'Type' => 'String'
      end

      example 'Person / Twitter Account [GET]', document: :contacts do
        explanation 'The Person\'s Twitter Account with the given ID'
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'primary',     'Primary'
        parameter 'remote_id',   'Remote ID'
        parameter 'screen_name', 'Screen Name'
      end

      example 'Person / Twitter Account [CREATE]', document: :contacts do
        explanation 'Create a Twitter Account associated with the Person'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'primary',     'Primary'
        parameter 'remote_id',   'Remote ID'
        parameter 'screen_name', 'Screen Name'
      end

      example 'Person / Twitter Account [UPDATE]', document: :contacts do
        explanation 'Update the Person\'s Twitter Account with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example 'Person / Twitter Account [DELETE]', document: :contacts do
        explanation 'Delete the Person\'s Twitter Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
