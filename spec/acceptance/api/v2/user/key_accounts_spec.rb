require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Key Accounts' do
  include_context :json_headers

  let(:resource_type) { 'person_key_accounts' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:key_account) { create(:key_account, person: user) }
  let(:id)           { key_account.id }

  let(:new_key_account_params) { build(:key_account, person: user).attributes }
  let(:form_data)              { build_data(new_key_account_params) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/user/key_accounts' do
      example 'Key Account [LIST]', document: :user do
        do_request
        explanation 'List of Key Accounts associated to current_user'
        check_collection_resource(2)
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/user/key_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'email',       'Email',      'Type' => 'String'
        response_field 'first_name',  'First Name', 'Type' => 'String'
        response_field 'last_name',   'Last Name',  'Type' => 'String'
        response_field 'person_id',   'Person Id',  'Type' => 'Number'
        response_field 'remote_id',   'Remote Id',  'Type' => 'Number'
      end

      example 'Key Account [GET]', document: :user do
        do_request
        check_resource
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/user/key_accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'email',      'Email', required: true
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'person_id',  'Person Id', required: true
        parameter 'remote_id',  'Remote Id', required: true
      end

      example 'Key Account [CREATE]', document: :user do
        do_request data: form_data
        expect(resource_object['email']).to eq new_key_account_params['email']
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/user/key_accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'email',      'Email', required: true
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'person_id',  'Person Id', required: true
        parameter 'remote_id',  'Remote Id', required: true
      end

      example 'Key Account [UPDATE]', document: :user do
        do_request data: form_data
        expect(resource_object['email']).to eq new_key_account_params['email']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/user/key_accounts/:id' do
      example 'Key Account [DELETE]', document: :user do
        do_request
        expect(response_status).to eq 200
      end
    end
  end
end
