require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'User > Options' do
  include_context :json_headers
  documentation_scope = :user_api_options

  let(:resource_type) { 'user_options' }
  let(:user) { create(:user_with_account) }
  let(:form_data) { build_data(attributes).merge }
  let!(:option) { create(:user_option, user: user) }
  let(:key) { option.key }
  let(:new_user_option_params) do
    attributes_for(:user_option)
      .merge(updated_in_db_at: option.updated_at)
      .select { |k, _v| expected_attribute_keys.include?(k.to_s) }
  end
  let(:form_data) { build_data(new_user_option_params) }
  let(:expected_attribute_keys) do
    %w(
      created_at
      key
      updated_at
      updated_in_db_at
      value
    )
  end
  let(:additional_attribute_keys) { [] }
  context 'authorized user' do
    before { api_login(user) }
    get '/api/v2/user/options' do
      example 'Option [LIST]', document: documentation_scope do
        explanation 'List of Options'
        do_request
        check_collection_resource(1, additional_attribute_keys)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    # show
    get '/api/v2/user/options/:key' do
      with_options scope: [:data, :attributes] do
        response_field 'key', 'Key to reference option (only contain alphanumeric and underscore chars)', 'Type' => 'String'
        response_field 'value', 'Value of option', 'Type' => 'String'
      end

      example 'Option [GET]', document: documentation_scope do
        explanation 'The Option for the given key'
        do_request
        check_resource(additional_attribute_keys)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    # create
    post '/api/v2/user/options' do
      with_options scope: [:data, :attributes] do
        parameter 'key', 'Key to reference option (only contain alphanumeric and underscore chars)'
        parameter 'value', 'Value of option'
      end
      example 'Option [CREATE]', document: documentation_scope do
        explanation 'Create Option'
        do_request data: form_data
        check_resource(additional_attribute_keys)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 201
      end
    end

    # update
    put '/api/v2/user/options/:key' do
      with_options scope: [:data, :attributes] do
        parameter 'value', 'Value of option'
      end
      example 'Option [UPDATE]', document: documentation_scope do
        explanation 'Update Option'
        do_request data: form_data
        check_resource(additional_attribute_keys)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    # destroy
    delete '/api/v2/user/options/:key' do
      example 'Option [DELETE]', document: documentation_scope do
        explanation 'Delete Option'
        do_request

        expect(response_status).to eq 204
      end
    end
  end
end
