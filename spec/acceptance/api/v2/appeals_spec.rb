require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Appeals' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'appeal' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let(:excluded) { 0 }
  let!(:appeal)  { create(:appeal, account_list: account_list) }
  let(:id)       { appeal.id }

  let(:form_data) { build_data(name: 'New Appeal Name', 'account_list_id': account_list_id) }

  let(:expected_attribute_keys) do
    %w(
      amount
      contacts
      created_at
      currencies
      description
      donations
      end_date
      name
      total_currency
      updated_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/appeals' do
      parameter 'account_list_id', 'Account List ID', scope: :filters
      response_field :data,        'Data', 'Type' => 'Array[Object]'

      example_request 'list appeals of account list' do
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/appeals/:id' do
      parameter 'account_list_id', 'Account List ID', scope: :filters
      parameter 'excluded',        'Show excluded contacts', required: true, scope: :filters
      with_options scope: [:data, :attributes] do
        response_field 'amount',         'Amount',         'Type' => 'Number'
        response_field 'contacts',       'Contacts',       'Type' => 'Array[Contact]'
        response_field 'created_at',     'Created At',     'Type' => 'String'
        response_field 'currencies',     'Currencies',     'Type' => 'Array[String]'
        response_field 'description',    'Description',    'Type' => 'String'
        response_field 'donations',      'Donations',      'Type' => 'Array[Object]'
        response_field 'end_date',       'End Date',       'Type' => 'String'
        response_field 'name',           'Name',           'Type' => 'String'
        response_field 'total_currency', 'Total currency', 'Type' => 'String'
      end

      example_request 'get appeal' do
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
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

      example 'create appeal' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/appeals/:id' do
      parameter 'account_list_id', 'Account List ID', required: true, scope: :filters

      with_options scope: [:data, :attributes] do
        parameter 'amount',      'Amount'
        parameter 'description', 'Description'
        parameter 'end_date',    'End Date'
        parameter 'name',        'Name'
      end

      example 'update appeals' do
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/appeals/:id' do
      parameter 'account_list_id', 'Account List ID', required: true, scope: :filters
      parameter 'id',              'ID', required: true

      example_request 'delete appeal' do
        expect(response_status).to eq 200
      end
    end
  end
end
