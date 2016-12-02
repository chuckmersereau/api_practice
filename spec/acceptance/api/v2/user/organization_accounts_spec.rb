require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Organization Accounts' do
  include_context :json_headers

  let!(:user)         { create(:user_with_full_account) }
  let(:resource_type) { 'organization_accounts' }

  let!(:organization_account) { create(:organization_account, person: user) }
  let(:id)                    { organization_account.uuid }

  let(:new_organization_account_params) do
    build(:organization_account).attributes.merge(organization_id: create(:organization).uuid, person_id: user.uuid)
  end

  let(:form_data) { build_data(new_organization_account_params) }

  before do
    allow_any_instance_of(DataServer).to receive(:validate_username_and_password).and_return(true)
    allow_any_instance_of(Person::OrganizationAccount).to receive(:queue_import_data)
    allow_any_instance_of(Person::OrganizationAccount).to receive(:set_up_account_list)
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/user/organization_accounts' do
      example 'Organization Account [LIST]', document: :user do
        do_request
        explanation 'List of Organization Accounts associated to current_user'

        check_collection_resource(2)
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/user/organization_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'organization_id', 'Organization Id', 'Type' => 'Number'
        response_field 'person_id',       'Person Id',       'Type' => 'String'
        response_field 'username',        'Username',        'Type' => 'String'
      end

      example 'Organization Account [GET]', document: :user do
        explanation 'The User\'s Organization Account with the given ID'
        do_request
        check_resource
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

      example 'Organization Account [Create]', document: :user do
        explanation 'Create an Organization Account associated with the current_user'
        do_request data: form_data

        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/user/organization_accounts/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'organization_id', 'Organization Id'
        parameter 'password',        'Password'
        parameter 'person_id',       'Person Id'
        parameter 'username',        'Username'
      end

      example 'Organization Account [UPDATE]', document: :user do
        explanation 'Update the current_user\'s Organization Account with the given ID'
        do_request data: form_data

        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/user/organization_accounts/:id' do
      example 'Organization Account [DELETE]', document: :user do
        explanation 'Delete the current_user\'s Organization Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
