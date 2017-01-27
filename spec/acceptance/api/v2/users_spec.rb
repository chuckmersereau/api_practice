require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Users' do
  include_context :json_headers

  let(:resource_type) { 'users' }
  let(:user) { create(:user_with_full_account) }

  let(:new_user_attributes) do
    attributes_for(:user_with_full_account).except(:access_token, :email, :locale, :time_zone)
                                           .merge(updated_in_db_at: user.updated_at).except(:email)
  end
  let(:form_data)           { build_data(new_user_attributes) }

  let(:resource_attributes) do
    %w(
      created_at
      first_name
      last_name
      preferences
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_lists
      email_addresses
      master_person
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/user' do
      response_field 'attributes',    'User object',                                'Type' => 'Object'
      response_field 'id',            'User ID',                                    'Type' => 'Number'
      response_field 'relationships', 'list of relationships related to that User', 'Type' => 'Array[Object]'
      response_field 'type',          'Will be User',                               'Type' => 'String'

      with_options scope: [:data, :attributes] do
        response_field 'created_at',       'Created At',       'Type' => 'String'
        response_field 'first_name',       'User first name',  'Type' => 'String'
        response_field 'last_name',        'User last name',   'Type' => 'String'
        response_field 'preferences',      'User preferences', 'Type' => 'Object'
        response_field 'updated_at',       'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', 'Type' => 'String'
      end

      example 'User [GET]', document: :entities do
        explanation 'The current_user'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/user' do
      with_options scope: [:data, :attributes] do
        parameter 'first_name',       'User first name', 'Type' => 'String', required: true
        parameter 'last_name',        'User last name',  'Type' => 'String'

        with_options scope: :preferences do
          parameter 'contacts_filter',       'Contacts Filter',        'Type' => 'String'
          parameter 'contacts_view_options', 'Contacts View Options',  'Type' => 'String'
          parameter 'default_account_list',  'Default Account List',   'Type' => 'String'
          parameter 'locale',                'User Locale',            'Type' => 'String'
          parameter 'setup',                 'User Preferences Setup', 'Type' => 'Boolean'
          parameter 'tab_orders',            'Tab Orders',             'Type' => 'String'
          parameter 'tasks_filter',          'Tasks Filter',           'Type' => 'String'
          parameter 'time_zone',             'User Time Zone',         'Type' => 'String'
        end
      end

      example 'User [UPDATE]', document: :entities do
        explanation 'Update the current_user'
        do_request data: form_data
        expect(resource_object['first_name']).to eq new_user_attributes[:first_name]
        expect(response_status).to eq 200
      end
    end
  end
end
