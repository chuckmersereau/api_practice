require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'User > Organization Accounts' do
  include_context :json_headers
  documentation_scope = :user_api_organization_accounts

  let!(:user)         { create(:user_with_full_account) }
  let(:resource_type) { 'organization_accounts' }

  let!(:organization_account) { create(:organization_account, person: user) }
  let(:id)                    { organization_account.uuid }

  let(:new_organization_account_params) do
    build(:organization_account)
      .attributes
      .merge(updated_in_db_at: organization_account.updated_at)
      .tap do |attrs|
        attrs.delete('person_id')
        attrs.delete('organization_id')
      end
  end

  let(:form_data) { build_data(new_organization_account_params, relationships: relationships) }

  let(:relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: user.uuid
        }
      },
      organization: {
        data: {
          type: 'organizations',
          id: create(:organization).uuid
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      created_at
      disable_downloads
      last_download
      locked_at
      remote_id
      token
      username
      updated_at
      updated_in_db_at
    )
  end

  before do
    allow_any_instance_of(DataServer).to receive(:validate_username_and_password).and_return(true)
    allow_any_instance_of(Person::OrganizationAccount).to receive(:queue_import_data)
    allow_any_instance_of(Person::OrganizationAccount).to receive(:set_up_account_list)
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/user/organization_accounts' do
      example 'Organization Account [LIST]', document: documentation_scope do
        do_request
        explanation 'List of Organization Accounts associated to current_user'

        check_collection_resource(2, %w(relationships))
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/user/organization_accounts/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',        'Created At',        type: 'String'
        response_field 'disable_downloads', 'Disable Downloads', type: 'String'
        response_field 'last_download',     'Last Download',     type: 'String'
        response_field 'locked_at',         'Locked At',         type: 'String'
        response_field 'remote_id',         'Remote Id',         type: 'String'
        response_field 'token',             'Token',             type: 'String'
        response_field 'username',          'Username',          type: 'String'
        response_field 'updated_at',        'Updated At',        type: 'String'
        response_field 'updated_in_db_at',  'Updated In Db At',  type: 'String'
      end

      example 'Organization Account [GET]', document: documentation_scope do
        explanation 'The User\'s Organization Account with the given ID'
        do_request
        check_resource(%w(relationships))
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

      example 'Organization Account [CREATE]', document: documentation_scope do
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

      example 'Organization Account [UPDATE]', document: documentation_scope do
        explanation 'Update the current_user\'s Organization Account with the given ID'
        do_request data: form_data

        expect(resource_object['username']).to eq new_organization_account_params['username']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/user/organization_accounts/:id' do
      example 'Organization Account [DELETE]', document: documentation_scope do
        explanation 'Delete the current_user\'s Organization Account with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
