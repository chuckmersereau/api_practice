require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Coaches' do
  include_context :json_headers
  documentation_scope = :account_lists_api_coaches

  let(:resource_type)    { 'users' }
  let!(:user)            { create(:user_with_account) }
  let!(:account_list)    { user.account_lists.order(:created_at).first }
  let(:account_list_id)  { account_list.id }
  let!(:coaches)         { create_list(:user_coach, 2) }
  let(:coach2)           { coaches.last }
  let(:id)               { coach2.id }

  let(:resource_attributes) do
    %w(
      created_at
      first_name
      last_name
      updated_at
      updated_in_db_at
    )
  end

  before do
    account_list.coaches += coaches
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/coaches' do
      example 'Coach [LIST]', document: documentation_scope do
        explanation 'List of Coaches associated to the Account List'
        do_request
        check_collection_resource(2, [])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/coaches/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'first_name',       'First name',       type: 'String'
        response_field 'last_name',        'Last name',        type: 'String'
        response_field 'created_at',       'Created At',       type: 'String'
        response_field 'updated_at',       'Updated At',       type: 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', type: 'String'
      end

      example 'Coach [GET]', document: documentation_scope do
        explanation 'The Account List Coach with the given ID'
        do_request
        check_resource([])
        expect(resource_object['first_name']).to eq coach2.first_name
        expect(resource_object['last_name']).to eq coach2.last_name
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/coaches/:id' do
      example 'Coach [DELETE]', document: documentation_scope do
        explanation 'Destroy the Account List Coach with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
