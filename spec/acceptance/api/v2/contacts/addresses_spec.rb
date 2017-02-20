require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Addresses' do
  include_context :json_headers
  documentation_scope = :contacts_api_addresses

  let!(:user) { create(:user_with_full_account) }
  let(:resource_type) { 'addresses' }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.uuid }

  let!(:address) { create(:address, addressable: contact) }
  let(:id) { address.uuid }

  let(:new_address) do
    build(:address, addressable: contact).attributes
                                         .reject { |key| key.to_s.end_with?('_id', '_at') }
                                         .merge(updated_in_db_at: address.updated_at)
  end
  let(:form_data) { build_data(new_address) }

  let(:expected_attribute_keys) do
    %w(
      city
      country
      created_at
      end_date
      geo
      historic
      location
      postal_code
      primary_mailing_address
      start_date
      state
      street
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/addresses' do
      example 'Address [LIST]', document: documentation_scope do
        explanation 'List of Addresses associated to the Contact'
        do_request

        check_collection_resource 1
        expect(response_status).to eq(200)
      end
    end

    get '/api/v2/contacts/:contact_id/addresses/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'city',                    'City',                    'Type' => 'String'
        response_field 'country',                 'Country',                 'Type' => 'String'
        response_field 'created_at',              'Created At',              'Type' => 'String'
        response_field 'end_date',                'End Date',                'Type' => 'String'
        response_field 'geo',                     'Geo',                     'Type' => 'String'
        response_field 'historic',                'Historic',                'Type' => 'Boolean'
        response_field 'location',                'Location',                'Type' => 'String'
        response_field 'postal_code',             'Postal Code',             'Type' => 'String'
        response_field 'primary_mailing_address', 'Primary Mailing Address', 'Type' => 'Boolean'
        response_field 'start_date',              'Start Date',              'Type' => 'String'
        response_field 'state',                   'State',                   'Type' => 'String'
        response_field 'street',                  'Street',                  'Type' => 'String'
        response_field 'updated_at',              'Updated At',              'Type' => 'String'
        response_field 'updated_in_db_at',        'Updated In Db At',        'Type' => 'String'
      end

      example 'Address [GET]', document: documentation_scope do
        explanation 'The Contact\'s Address with the given ID'
        do_request
        check_resource
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq(200)
      end
    end

    post '/api/v2/contacts/:contact_id/addresses' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'city',                    'City'
        parameter 'country',                 'Country'
        parameter 'end_date',                'End Date'
        parameter 'location',                'Location'
        parameter 'metro_area',              'Metro Area'
        parameter 'postal_code',             'Postal Code'
        parameter 'primary_mailing_address', 'Primary Mailing Address'
        parameter 'region',                  'Region'
        parameter 'remote_id',               'Remote ID'
        parameter 'seasonal',                'Seasonal'
        parameter 'start_date',              'Start Date'
        parameter 'state',                   'State'
        parameter 'street',                  'Street'
      end

      example 'Address [CREATE]', document: documentation_scope do
        explanation 'Create a Address associated with the Contact'
        do_request data: form_data

        expect(resource_object['street']).to(be_present) && eq(new_address['street'])
        expect(response_status).to eq(201)
      end
    end

    put '/api/v2/contacts/:contact_id/addresses/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'city',                    'City'
        parameter 'country',                 'Country'
        parameter 'end_date',                'End Date'
        parameter 'location',                'Location'
        parameter 'metro_area',              'Metro Area'
        parameter 'postal_code',             'Postal Code'
        parameter 'primary_mailing_address', 'Primary Mailing Address'
        parameter 'region',                  'Region'
        parameter 'remote_id',               'Remote ID'
        parameter 'seasonal',                'Seasonal'
        parameter 'start_date',              'Start Date'
        parameter 'state',                   'State'
        parameter 'street',                  'Street'
      end

      example 'Address [UPDATE]', document: documentation_scope do
        explanation 'Update the Contact\'s Address with the given ID'
        do_request data: form_data

        expect(resource_object['street']).to(be_present) && eq(new_address['street'])
        expect(response_status).to eq(200)
      end
    end

    delete '/api/v2/contacts/:contact_id/addresses/:id' do
      example 'Address [DELETE]', document: documentation_scope do
        explanation 'Delete the Contact\'s Address with the given ID'
        do_request
        expect(response_status).to eq(204)
      end
    end
  end
end
