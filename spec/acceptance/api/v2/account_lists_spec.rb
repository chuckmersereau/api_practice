require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists' do
  include_context :json_headers
  documentation_scope = :entities_account_lists

  let(:resource_type) { 'account_lists' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list) { user.account_lists.first }
  let(:id)           { account_list.uuid }

  let(:new_account_list) do
    build(:account_list)
      .attributes
      .except('creator_id')
      .merge(updated_in_db_at: account_list.updated_at)
  end

  let(:form_data) { build_data(new_account_list) }

  let(:resource_attributes) do
    %w(
      created_at
      currency
      default_currency
      home_country
      monthly_goal
      name
      tester
      total_pledges
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      notification_preferences
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists' do
      response_field :data, 'Data', 'Type' => 'Array[Object]'

      example 'List account lists', document: documentation_scope do
        explanation 'List of Account Lists'
        do_request
        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',              'Created At',       'Type' => 'String'
        response_field 'default_organization_id', 'Organization ID',  'Type' => 'Number'
        response_field 'monthly_goal',            'Monthly Goal',     'Type' => 'String'
        response_field 'name',                    'Account Name',     'Type' => 'String'
        response_field 'settings',                'Settings',         'Type' => 'Object'
        response_field 'updated_at',              'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at',        'Updated In Db At', 'Type' => 'String'
      end

      example 'Retreive an account list', document: documentation_scope do
        explanation 'The Account List with the given ID'
        do_request
        check_resource(['relationships'])
        expect(resource_object['name']).to eq account_list.name
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/account_lists/:id' do
      parameter 'id', 'ID of the Account List', required: true

      with_options scope: [:data, :attributes] do
        parameter 'name',             'Account Name', required: true

        with_options scope: :settings do
          parameter 'currency',               'Currency',               'Type' => 'String'
          parameter 'home_country',           'Home Country',           'Type' => 'String'
          parameter 'log_debug_info',         'Log Debug Info',         'Type' => 'String'
          parameter 'ministry_country',       'Ministry Country',       'Type' => 'String'
          parameter 'monthly_goal',           'Monthly Goal',           'Type' => 'Number'
          parameter 'owner',                  'Owner',                  'Type' => 'String'
          parameter 'salary_currency',        'Salary Currency',        'Type' => 'String'
          parameter 'salary_organization_id', 'Salary Organization Id', 'Type' => 'String'
          parameter 'tester',                 'Tester',                 'Type' => 'String'
        end
      end

      example 'Update an account list', document: documentation_scope do
        explanation 'Update the Account List with the given ID'
        do_request data: form_data
        expect(resource_object['name']).to eq new_account_list['name']
        expect(response_status).to eq 200
      end
    end
  end
end
