require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Linkedin Accounts' do
  include_context :json_headers

  let(:resource_type) { 'person_linkedin_accounts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:contact)   { create(:contact, account_list: account_list) }
  let(:contact_id) { contact.uuid }

  let!(:person)   { create(:person) }
  let(:person_id) { person.uuid }

  let!(:linkedin_accounts) { create_list(:linkedin_account, 2, person: person) }
  let(:linkedin_account)   { linkedin_accounts.first }
  let(:id)                 { linkedin_account.uuid }

  let(:new_facebook_account) { build(:linkedin_account).attributes.merge(person_id: person.uuid) }
  let(:form_data)            { build_data(new_facebook_account) }

  let(:expected_attribute_keys) do
    %w(
      authenticated
      created_at
      first_name
      last_name
      public_url
      remote_id
      updated_at
    )
  end

  context 'authorized user' do
    before do
      contact.people << person
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID', required: true
      response_field 'data',  'Data', 'Type' => 'Array[Object]'

      example 'Person / LinkedIn Account [LIST]', document: :contacts do
        explanation 'List of LinkedIn Accounts associated to the Person'
        do_request
        check_collection_resource(2)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at', 'Created At', 'Type' => 'String'
        response_field 'first_name', 'First Name', 'Type' => 'String'
        response_field 'last_name',  'Last name',  'Type' => 'Number'
        response_field 'public_url', 'Public URL', 'Type' => 'String'
        response_field 'remote_id',  'Remote ID',  'Type' => 'Number'
        response_field 'updated_at', 'Updated At', 'Type' => 'String'
      end

      example 'Person / LinkedIn Account [GET]', document: :contacts do
        explanation 'List of LinkedIn Accounts associated to the Person'
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'public_url', 'Public URL'
        parameter 'remote_id',  'Remote ID'
      end

      example 'Person / LinkedIn Account [CREATE]', document: :contacts do
        explanation 'Create a LinkedIn Account associated with the Person'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'public_url', 'Public URL'
        parameter 'remote_id',  'Remote ID'
      end

      example 'Person / LinkedIn Account [UPDATE]', document: :contacts do
        explanation 'Update the Person\'s LinkedIn Account with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example 'Person / LinkedIn Account [DELETE]', document: :contacts do
        explanation 'Delete the Person\'s LinkedIn Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
