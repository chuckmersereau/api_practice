require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Organization Accounts' do
  let(:resource_type) { 'person-organization-accounts' }
  let!(:user) { create(:user_with_full_account) }
  let!(:organization_account) { create(:organization_account, person: user) }
  let(:id) { organization_account.id }
  let(:new_organization_account_params) { build(:organization_account).attributes }
  let(:form_data) { build_data(new_organization_account_params) }

  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/user/organization_accounts' do
      example_request 'get organization accounts' do
        explanation 'List of Organization Accounts associated to current_user'
        check_collection_resource(2, ['relationships'])
        expect(status).to eq 200
      end
    end
    get '/api/v2/user/organization_accounts/:id' do
      example_request 'get organization account' do
        check_resource(['relationships'])
        expect(status).to eq 200
      end
    end
    post '/api/v2/user/organization_accounts' do
      with_options required: true, scope: [:data, :attributes] do
        parameter :username, 'Username'
        parameter :password, 'Password'
        parameter :person_id, 'Person Id'
        parameter :organization_id, 'Organization Id'
      end

      example 'create organization account' do
        do_request data: form_data
        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(status).to eq 200
      end
    end

    put '/api/v2/user/organization_accounts/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter :username, 'Username'
        parameter :password, 'Password'
        parameter :person_id, 'Person Id'
        parameter :organization_id, 'Organization Id'
      end

      example 'update notification' do
        do_request data: form_data
        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(status).to eq 200
      end
    end

    delete '/api/v2/user/organization_accounts/:id' do
      example_request 'delete notification' do
        expect(status).to eq 200
      end
    end
  end
end
