require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Organization Accounts' do
  let(:resource_type) { 'person_organization_accounts' }

  let!(:user)                 { create(:user_with_full_account) }
  let!(:organization_account) { create(:organization_account, person: user) }
  let(:id)                    { organization_account.id }

  let(:new_organization_account_params) { build(:organization_account, person: user).attributes }
  let(:form_data)                       { build_data(new_organization_account_params) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/user/organization_accounts' do
      example_request 'get organization accounts' do
        explanation 'List of Organization Accounts associated to current_user'

        check_collection_resource(2, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/user/organization_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'organization_id', 'Organization Id', 'Type' => 'Number'
        response_field 'person_id',       'Person Id',       'Type' => 'String'
        response_field 'username',        'Username',        'Type' => 'String'
      end

      example_request 'get organization account' do
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/user/organization_accounts' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'organization_id', 'Organization Id'
        parameter 'password',        'Password'
        parameter 'person_id',       'Person Id'
        parameter 'username',        'Username'
      end

      example 'create organization account' do
        do_request data: form_data

        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/user/organization_accounts/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'organization_id', 'Organization Id'
        parameter 'password',        'Password'
        parameter 'person_id',       'Person Id'
        parameter 'username',        'Username'
      end

      example 'update notification' do
        do_request data: form_data

        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/user/organization_accounts/:id' do
      example_request 'delete notification' do
        expect(response_status).to eq 200
      end
    end
  end
end
