require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > People > Twitter Accounts' do
  include_context :json_headers
  documentation_scope = :people_api_twitter_accounts

  let(:resource_type) { 'twitter_accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let!(:person)   { create(:person) }
  let(:person_id) { person.uuid }

  let!(:twitter_accounts) { create_list(:twitter_account, 2, person: person) }
  let(:twitter_account)   { twitter_accounts.first }
  let(:id)                { twitter_account.uuid }

  let(:new_twitter_account) do
    build(:twitter_account).attributes
                           .reject { |key| key.to_s.end_with?('_id') }
                           .merge(updated_in_db_at: twitter_account.updated_at, remote_id: 'RandomID')
  end

  let(:form_data) { build_data(new_twitter_account) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      primary
      remote_id
      screen_name
      updated_at
      updated_in_db_at
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

      example 'Twitter Account [LIST]', document: documentation_scope do
        explanation 'List of Twitter Accounts associated to the Person'
        do_request
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',       'Created At',       'Type' => 'String'
        response_field 'primary',          'Primary',          'Type' => 'Boolean'
        response_field 'remote_id',        'Remote ID',        'Type' => 'Number'
        response_field 'screen_name',      'Screen Name',      'Type' => 'String'
        response_field 'updated_at',       'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', 'Type' => 'String'
      end

      example 'Twitter Account [GET]', document: documentation_scope do
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

      example 'Twitter Account [CREATE]', document: documentation_scope do
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

      example 'Twitter Account [UPDATE]', document: documentation_scope do
        explanation 'Update the Person\'s Twitter Account with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/twitter_accounts/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example 'Twitter Account [DELETE]', document: documentation_scope do
        explanation 'Delete the Person\'s Twitter Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
