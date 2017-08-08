require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Google Integrations' do
  before do
    allow_any_instance_of(GoogleIntegration).to receive(:calendars).and_return([])
  end

  include_context :json_headers
  let(:resource_type) { 'google_integrations' }
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:form_data) { build_data(attributes) }

  let(:google_account) { create(:google_account, person: user) }
  let(:google_account_id) { google_account.uuid }

  let!(:google_integration) { create(:google_integration, account_list: account_list, google_account: google_account) }
  let(:id) { google_integration.uuid }

  let(:resource_attributes) do
    %w(
      created_at
      updated_at
      updated_in_db_at
      calendar_integration
      calendar_integrations
      calendar_id
      calendar_name
      email_integration
      contacts_integration
      calendars
    )
  end

  let(:additional_attribute_keys) do
    %w(
      relationships
    )
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.uuid
        }
      },
      google_account: {
        data: {
          type: 'google_accounts',
          id: google_account.uuid
        }
      }
    }
  end

  let(:new_google_integration) do
    {
      calendar_id: 'test@test.com',
      calendar_name: 'test123',
      calendar_integration: false,
      calendar_integrations: [],
      contacts_integration: false,
      email_integration: false,
      updated_in_db_at: google_integration.updated_at
    }
  end

  let(:form_data) { build_data(new_google_integration, relationships: relationships) }

  documentation_scope = :user_api_google_integrations

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/user/google_accounts/:google_account_id/google_integrations' do
      example 'Google Integration [LIST]', document: documentation_scope do
        explanation 'List of Google Integrations'
        do_request

        check_collection_resource(1, additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # show
    get '/api/v2/user/google_accounts/:google_account_id/google_integrations/:id' do
      with_options scope: [:data, :attributes] do
        # list out the attributes here
        response_field 'name_of_attribute', 'Name of Attribute', type: 'The Attribute Type (String, Boolean, etc)'
      end

      example 'Google Integration [GET]', document: documentation_scope do
        explanation 'The Google Integration for the given ID'
        do_request

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # create
    post '/api/v2/user/google_accounts/:google_account_id/google_integrations' do
      with_options scope: [:data, :attributes] do
        # list out the POST params here
        parameter 'attribute_name', 'Description of the Attribute'
      end

      example 'Google Integration [CREATE]', document: documentation_scope do
        explanation 'Create Google Integration'
        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 201
      end
    end

    # update
    put '/api/v2/user/google_accounts/:google_account_id/google_integrations/:id' do
      with_options scope: [:data, :attributes] do
        # list out the PUT params here
        parameter 'attribute_name', 'Description of the Attribute'
      end

      example 'Google Integration [UPDATE]', document: documentation_scope do
        explanation 'Update Google Integration'

        # Merge with the updated_in_db_at value provided by the server.
        # Ex: updated_in_db_at: email_address.updated_at
        do_request data: form_data
        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # update
    patch '/api/v2/user/google_accounts/:google_account_id/google_integrations/:id' do
      with_options scope: [:data, :attributes] do
        # list out the PATCH params here
        parameter 'attribute_name', 'Description of the Attribute'
      end

      example 'Google Integration [UPDATE]', document: documentation_scope do
        explanation 'Update Google Integration'

        # Merge with the updated_in_db_at value provided by the server.
        # Ex: updated_in_db_at: email_address.updated_at
        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # destroy
    delete '/api/v2/user/google_accounts/:google_account_id/google_integrations/:id' do
      example 'Google Integration [DELETE]', document: documentation_scope do
        explanation 'Delete Google Integration'
        do_request

        expect(response_status).to eq 204
      end
    end
  end
end
