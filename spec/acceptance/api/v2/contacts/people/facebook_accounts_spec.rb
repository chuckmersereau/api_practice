require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > People > Facebook Accounts' do
  include_context :json_headers
  documentation_scope = :people_api_facebook_accounts

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
    build(:facebook_account).attributes
                            .reject { |key| key.to_s.end_with?('_id') }
                            .merge(updated_in_db_at: facebook_account.updated_at)
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
      response_field 'data',  'Data', type: 'Array[Object]'

      example 'Facebook Account [LIST]', document: documentation_scope do
        explanation 'List of Facebook Accounts associated to the Person'
        do_request
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',       'Created At',       type: 'String'
        response_field 'first_name',       'First Name',       type: 'String'
        response_field 'last_name',        'Last name',        type: 'Number'
        response_field 'remote_id',        'Remote ID',        type: 'Number'
        response_field 'updated_at',       'Updated At',       type: 'String'
        response_field 'updated_at_in_db', 'Updated In Db At', type: 'String'
        response_field 'username',         'Username',         type: 'String'
      end

      example 'Facebook Account [GET]', document: documentation_scope do
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

      example 'Facebook Account [CREATE]', document: documentation_scope do
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

      example 'Facebook Account [UPDATE]', document: documentation_scope do
        explanation 'Update the Person\'s Facebook Account with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/facebook_accounts/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example 'Facebook Account [DELETE]', document: documentation_scope do
        explanation 'Delete the Person\'s Facebook Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
