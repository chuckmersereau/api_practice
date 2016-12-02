require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Linkedin Accounts' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'person_linkedin_accounts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:contact)   { create(:contact, account_list_id: account_list.id) }
  let(:contact_id) { contact.id }

  let!(:person)   { create(:person) }
  let(:person_id) { person.id }

  let!(:linkedin_accounts) { create_list(:linkedin_account, 2, person: person) }
  let(:linkedin_account)   { linkedin_accounts.first }
  let(:id)                 { linkedin_account.id }

  let(:new_facebook_account) { build(:linkedin_account).attributes }
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

      example_request 'list linkedin accounts of person' do
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

      example_request 'get linkedin account' do
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

      example 'create linkedin account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'public_url', 'Public URL'
        parameter 'remote_id',  'Remote ID'
      end

      example 'update linkedin account' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/linkedin_accounts/:id' do
      parameter 'contact_id', 'Contact ID', required: true
      parameter 'person_id',  'Person ID',  required: true

      example_request 'delete linkedin account' do
        expect(response_status).to eq 200
      end
    end
  end
end
