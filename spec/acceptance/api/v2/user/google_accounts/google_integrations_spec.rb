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
  let(:google_account_id) { google_account.id }

  let!(:google_integration) { create(:google_integration, account_list: account_list, google_account: google_account) }
  let(:id) { google_integration.id }

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
      email_blacklist
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
          id: account_list.id
        }
      },
      google_account: {
        data: {
          type: 'google_accounts',
          id: google_account.id
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

    describe 'update' do
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

        [:calendar_integrations, :email_blacklist].each do |attribute_name|
          example "It updates the #{attribute_name} array", document: false do
            google_integration.update!(calendar_integration: true, attribute_name => ['Test'])
            data = form_data
            data[:attributes][:calendar_integration] = true
            data[:attributes][attribute_name] = %w(Test 1234)

            do_request data: data
            check_resource(additional_attribute_keys)
            expect(response_status).to eq 200
            expect(json_response['data']['attributes'][attribute_name.to_s]).to eq(%w(Test 1234))
          end

          example "It updates the #{attribute_name} array to be empty", document: false do
            google_integration.update!(calendar_integration: true, attribute_name => ['Test'])
            data = form_data
            data[:attributes][:calendar_integration] = true
            data[:attributes][attribute_name] = []

            do_request data: data
            check_resource(additional_attribute_keys)
            expect(response_status).to eq 200
            expect(json_response['data']['attributes'][attribute_name.to_s]).to eq([])
          end

          example "It does not set the #{attribute_name} array if the param is not sent", document: false do
            google_integration.update!(calendar_integration: true, attribute_name => ['Test'])
            data = form_data
            data[:attributes][:calendar_integration] = true
            data[:attributes].delete(attribute_name)

            do_request data: data
            check_resource(additional_attribute_keys)
            expect(response_status).to eq 200
            expect(json_response['data']['attributes'][attribute_name.to_s]).to eq(['Test'])
          end
        end
      end

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
