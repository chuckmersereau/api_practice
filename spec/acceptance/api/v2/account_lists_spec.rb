require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists' do
  include_context :json_headers

  let(:resource_type) { 'account_lists' }
  let!(:user)         { create(:user_with_account) }

  let(:account_list) { user.account_lists.first }
  let(:id)           { account_list.id }

  let(:new_account_list) { build(:account_list).attributes }
  let(:form_data)        { build_data(new_account_list) }

  let(:expected_attribute_keys) do
    %w(
      created_at
      default_organization_id
      monthly_goal
      name
      total_pledges
      updated_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists' do
      response_field :data, 'Data', 'Type' => 'Array[Object]'

      example 'Account List [LIST]', document: :entities do
        do_request
        check_collection_resource(1)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',              'Created At',      'Type' => 'String'
        response_field 'default_organization_id', 'Organization ID', 'Type' => 'Number'
        response_field 'monthly_goal',            'Monthly Goal',    'Type' => 'String'
        response_field 'name',                    'Account Name',    'Type' => 'String'
        response_field 'updated_at',              'Updated At',      'Type' => 'String'
      end

      example 'Account List [GET]', document: :entities do
        do_request
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['name']).to eq account_list.name
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/account_lists/:id' do
      parameter 'id', 'ID of the Account List', required: true

      with_options scope: [:data, :attributes] do
        parameter 'name',     'Account Name', required: true
        parameter 'settings', 'Settings'
      end

      example 'Account List [UPDATE]', document: :entities do
        do_request data: form_data
        expect(resource_object['name']).to eq new_account_list['name']
        expect(response_status).to eq 200
      end
    end
  end
end
