require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Phones' do
  include_context :json_headers

  let(:resource_type) { 'phone_numbers' }
  let!(:user)         { create(:user_with_full_account) }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.uuid }

  let(:person)    { create(:person, contacts: [contact]) }
  let(:person_id) { person.uuid }

  let!(:phone) { create(:phone_number, person: person) }
  let(:id)     { phone.uuid }

  let(:new_phone) do
    build(:phone_number, number: '3561987123').attributes.merge(person_id: person.uuid,
                                                                updated_in_db_at: phone.updated_at)
  end
  let(:form_data) { build_data(new_phone) }

  let(:expected_attribute_keys) do
    %w(
      country_code
      created_at
      historic
      location
      number
      primary
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/people/:person_id/phones' do
      example 'Phone [LIST]', document: :people do
        explanation 'List of Phone Numbers associated to the Person'
        do_request
        check_collection_resource(1)
        expect(response_status).to eq(200)
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/phones/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'country_code',     'Country Code',     'Type' => 'String'
        response_field 'created_at',       'Created At',       'Type' => 'String'
        response_field 'historic',         'Historic',         'Type' => 'Boolean'
        response_field 'location',         'Location',         'Type' => 'String'
        response_field 'number',           'Number',           'Type' => 'String'
        response_field 'primary',          'Primary',          'Type' => 'Boolean'
        response_field 'updated_at',       'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at', 'Updated In Db At', 'Type' => 'String'
      end

      example 'Phone [GET]', document: :people do
        explanation 'The Person\'s Phone Number with the given ID'
        do_request
        expect(resource_object.keys).to match_array expected_attribute_keys
        check_resource
        expect(response_status).to eq(200)
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/phones' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'country-code', 'Country Code'
        parameter 'location',     'Location'
        parameter 'number',       'Number'
        parameter 'person_id',    'Person ID'
        parameter 'primary',      'Primary'
        parameter 'remote_id',    'Remote ID'
      end

      example 'Phone [CREATE]', document: :people do
        explanation 'Create a Phone Number associated with the Person'
        do_request data: form_data

        expect(resource_object['number']).to eq new_phone['number']
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/phones/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'country-code', 'Country Code'
        parameter 'location',     'Location'
        parameter 'number',       'Number'
        parameter 'person_id',    'Person ID'
        parameter 'primary',      'Primary'
        parameter 'remote_id',    'Remote ID'
      end

      example 'Phone [UPDATE]', document: :people do
        explanation 'Update Person\'s Phone Number with the given ID'
        do_request data: form_data
        expect(resource_object['number']).to eq new_phone['number']
        expect(response_status).to eq(200)
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/phones/:id' do
      example 'Phone [DELETE]', document: :people do
        explanation 'Delete Person\'s Phone Number with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
