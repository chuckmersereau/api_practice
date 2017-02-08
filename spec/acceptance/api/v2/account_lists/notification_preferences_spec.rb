require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Notification Preferences' do
  include_context :json_headers

  let(:resource_type) { 'notification_preferences' }
  let(:user) { create(:user_with_account) }

  let!(:account_list)              { user.account_lists.first }
  let(:account_list_id)            { account_list.uuid }
  let!(:notification_preferences)  do
    create_list(:notification_preference, 2,
                account_list_id: account_list.id,
                actions: 'email',
                notification_type_id: notification_type.id)
  end
  let(:notification_preference)    { notification_preferences.first }
  let(:id)                         { notification_preference.uuid }

  let(:notification_type) { create(:notification_type) }
  # let(:new_notification_preference) do
  #   build(:notification_preference).attributes.merge(updated_in_db_at: notification_preference.updated_at)
  #     .except('notification_type_id')
  # end
  let(:form_data) do
    build_data(attributes, relationships: relationships)
  end

  let(:relationships) do
    {
      notification_type: {
        data: {
          type: 'notification_types',
          id: notification_type.uuid
        }
      }
    }
  end

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  # let(:form_data) { build_data(attributes) }

  # List your expected resource keys vertically here (alphabetical please!)
  let(:resource_attributes) do
    %w(
      actions
      created_at
      type
      updated_at
      updated_in_db_at
    )
  end

  let(:additional_attribute_keys) do
    %w(
      relationships
    )
  end

  let(:resource_associations) do
    %w(
      account_list
      notification_type
    )
  end

  documentation_scope = :account_lists

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/notification_preferences' do
      parameter 'account_list_id', 'Account List ID', required: true
      response_field 'data',       'List of Notification Preferences', 'Type' => 'Array[Object]'

      example 'Notification Preference [LIST]', document: documentation_scope do
        explanation 'List of Notification Preferences'
        do_request
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/notification_preferences/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'actions',              'Actions',              'Type' => 'String'
        response_field 'created_at',           'Created At',           'Type' => 'String'
        response_field 'type',                 'Notification Type',    'Type' => 'String'
        response_field 'updated_at',           'Updated At',           'Type' => 'String'
        response_field 'updated_in_db_at',     'Updated In Db At',     'Type' => 'String'
      end

      example 'Notification Preference [GET]', document: documentation_scope do
        explanation 'The Notification Preference for the given ID'
        do_request
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/account_lists/:account_list_id/notification_preferences' do
      with_options scope: [:data, :attributes] do
        parameter 'actions',             'Actions',           'Type' => 'String'
        parameter 'updated_in_db_at',    'Updated In Db At',  'Type' => 'String'
      end

      let(:attributes) do
        {
          actions: 'email'
        }
      end

      example 'Notification Preference [CREATE]', document: documentation_scope do
        explanation 'Create Notification Preference'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end

    delete '/api/v2/account_lists/:account_list_id/notification_preferences/:id' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'ID', required: true

      example 'Notification Preference [DELETE]', document: documentation_scope do
        explanation 'Delete Notification Preference'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
