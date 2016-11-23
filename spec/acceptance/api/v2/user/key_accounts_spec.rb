require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Key Accounts' do
  let(:resource_type) { 'person-key-accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:key_account) { create(:key_account, person: user) }
  let(:id) { key_account.id }
  let(:new_key_account_params) { build(:key_account, person: user).attributes }
  let(:form_data) { build_data(new_key_account_params) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/user/key-accounts' do
      example_request 'get organization accounts' do
        explanation 'List of Organization Accounts associated to current_user'
        check_collection_resource(2)
        expect(status).to eq 200
      end
    end

    get '/api/v2/user/key-accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'email',       'Email', 'Type' => 'String'
        response_field 'first_name',  'First Name', 'Type' => 'String'
        response_field 'last_name',   'Last Name', 'Type' => 'String'
        response_field 'person_id',   'Person Id', 'Type' => 'Integer'
        response_field 'remote_id',   'Remote Id', 'Type' => 'Integer'
      end
      example_request 'get organization account' do
        check_resource
        expect(status).to eq 200
      end
    end

    post '/api/v2/user/key-accounts' do
      with_options scope: [:data, :attributes] do
        parameter 'email',      'Email', required: true
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'person_id',  'Person Id', required: true
        parameter 'remote_id',  'Remote Id', required: true
      end

      example 'create organization account' do
        do_request data: form_data
        expect(resource_object['email']).to eq new_key_account_params['email']
        expect(status).to eq 200
      end
    end

    put '/api/v2/user/key-accounts/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'email',      'Email', required: true
        parameter 'first_name', 'First Name'
        parameter 'last_name',  'Last Name'
        parameter 'person_id',  'Person Id', required: true
        parameter 'remote_id',  'Remote Id', required: true
      end

      example 'update notification' do
        do_request data: form_data
        expect(resource_object['email']).to eq new_key_account_params['email']
        expect(status).to eq 200
      end
    end

    delete '/api/v2/user/key-accounts/:id' do
      example_request 'delete notification' do
        expect(status).to eq 200
      end
    end
  end
end
