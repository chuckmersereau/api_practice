require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Facebook Accounts' do
  include_context :json_headers

  let(:resource_type) { 'facebook_accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let!(:person)   { create(:person) }
  let(:person_id) { person.uuid }

  let!(:facebook_accounts) { create_list(:facebook_account, 2, person: person) }
  let(:facebook_account)   { facebook_accounts.first }
  let(:id)                 { facebook_account.uuid }

  let(:new_facebook_account) do
    build(:facebook_account).attributes.merge(updated_in_db_at: facebook_account.updated_at, person_id: person.uuid)
  end
  let(:form_data) { build_data(new_facebook_account) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      first_name
      last_name
      remote_id
      updated_at
      updated_in_db_at
      username
    )
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID', required: true
      response_field 'data',  'Data', 'Type' => 'Array[Object]'

      example 'Person / Facebook Account [LIST]', document: :contacts do
        explanation 'List of Facebook Accounts associated to the Person'
        do_request
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',       'Created At',       'Type' => 'String'
        response_field 'first_name',       'First Name',       'Type' => 'String'
        response_field 'last_name',        'Last name',        'Type' => 'Number'
        response_field 'remote_id',        'Remote ID',        'Type' => 'Number'
        response_field 'updated_at',       'Updated At',       'Type' => 'String'
        response_field 'updated_at_in_db', 'Updated In Db At', 'Type' => 'String'
        response_field 'username',         'Username',         'Type' => 'String'
      end

      example 'Person / Facebook Account [GET]', document: :contacts do
        explanation 'The Person\'s Facebook Account with the given ID'
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'remote_id',  'Remote ID'
        parameter 'username',   'Username'
      end

      example 'Person / Facebook Account [CREATE]', document: :contacts do
        explanation 'Create a Facebook Account associated with the Person'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'remote_id',  'Remote ID'
        parameter 'username',   'Username'
      end

      example 'Person / Facebook Account [UPDATE]', document: :contacts do
        explanation 'Update the Person\'s Facebook Account with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example 'Person / Facebook Account [DELETE]', document: :contacts do
        explanation 'Delete the Person\'s Facebook Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
