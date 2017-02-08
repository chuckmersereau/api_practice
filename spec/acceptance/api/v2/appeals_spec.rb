require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Appeals' do
  include_context :json_headers

  let(:resource_type) { 'appeals' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let(:excluded) { 0 }
  let!(:appeal)  { create(:appeal, account_list: account_list) }
  let(:id)       { appeal.uuid }

  let(:form_data) do
    attributes = {
      name: 'New Appeal Name',
      updated_in_db_at: appeal.updated_at
    }

    build_data(attributes, relationships: relationships)
  end

  let(:relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.uuid
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      account_list_id
      amount
      created_at
      currencies
      description
      donations
      end_date
      name
      total_currency
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_list
      contacts
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/appeals' do
      parameter 'account_list_id', 'Account List ID', scope: :filters
      response_field :data,        'Data', 'Type' => 'Array[Object]'

      example 'Appeal [LIST]', document: :entities do
        explanation 'List of Appeals'
        do_request
        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    get '/api/v2/appeals/:id' do
      parameter 'account_list_id', 'Account List ID', scope: :filters
      parameter 'excluded',        'Show excluded contacts', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        response_field 'amount',          'Amount',            'Type' => 'Number'
        response_field 'contacts',        'Contacts',          'Type' => 'Array[Contact]'
        response_field 'created_at',      'Created At',        'Type' => 'String'
        response_field 'currencies',      'Currencies',        'Type' => 'Array[String]'
        response_field 'description',     'Description',       'Type' => 'String'
        response_field 'donations',       'Donations',         'Type' => 'Array[Object]'
        response_field 'end_date',        'End Date',          'Type' => 'String'
        response_field 'name',            'Name',              'Type' => 'String'
        response_field 'total_currency',  'Total currency',    'Type' => 'String'
        response_field 'updated_at',      'Updated At',        'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', 'Type' => 'String'
      end

      example 'Appeal [GET]', document: :entities do
        explanation 'The Appeal with the given ID'
        do_request
        check_resource(%w(relationships))
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    post '/api/v2/appeals' do
      with_options scope: [:data, :attributes] do
        parameter 'account_list_id', 'Account List ID', required: true
        parameter 'amount',          'Amount'
        parameter 'description',     'Description'
        parameter 'end_date',        'End Date'
        parameter 'name',            'Name', required: true
      end

      example 'Appeal [CREATE]', document: :entities do
        explanation 'Create an Appeal'
        do_request data: form_data
        expect(response_status).to eq(201), invalid_status_detail
      end
    end

    put '/api/v2/appeals/:id' do
      parameter 'account_list_id', 'Account List ID', required: true, scope: :filters

      with_options scope: [:data, :attributes] do
        parameter 'amount',      'Amount',      'Type' => 'String'
        parameter 'description', 'Description', 'Type' => 'String'
        parameter 'end_date',    'End Date',    'Type' => 'String'
        parameter 'name',        'Name',        'Type' => 'String'
      end

      example 'Appeal [UPDATE]', document: :entities do
        explanation 'Update the Appeal with the given ID'
        do_request data: form_data
        expect(response_status).to eq(200), invalid_status_detail
      end
    end

    delete '/api/v2/appeals/:id' do
      parameter 'account_list_id', 'Account List ID', required: true, scope: :filters
      parameter 'id',              'ID', required: true

      example 'Appeal [DELETE]', document: :entities do
        explanation 'Delete the Appeal with the given ID'
        do_request
        expect(response_status).to eq(204), invalid_status_detail
      end
    end
  end
end
