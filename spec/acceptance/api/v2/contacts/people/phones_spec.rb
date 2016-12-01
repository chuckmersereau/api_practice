require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Phones' do
  let(:resource_type) { 'phone_numbers' }

  let!(:user)      { create(:user_with_full_account) }
  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:person)     { create(:person, contacts: [contact]) }
  let!(:phone)     { create(:phone_number, person: person) }
  let(:contact_id) { contact.id }
  let(:person_id)  { person.id }
  let(:id)         { phone.id }

  let(:new_phone) { build(:phone_number, number: '3561987123', person: person).attributes }
  let(:form_data) { build_data(new_phone) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/phones' do
      example_request 'get phones' do
        explanation('List of phone numbers associated to the person')
        check_collection_resource(1)
        expect(response_status).to eq(200)
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/phones/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'country-code', 'Country Code', 'Type' => 'Integer'
        response_field 'created_at',   'Created At',   'Type' => 'String'
        response_field 'historic',     'Historic',     'Type' => 'Boolean'
        response_field 'location',     'Location',     'Type' => 'String'
        response_field 'number',       'Number',       'Type' => 'String'
        response_field 'primary',      'Primary',      'Type' => 'Boolean'
        response_field 'updated_at',   'Updated At',   'Type' => 'String'
      end

      example_request 'get phone number' do
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

      example 'create phone number' do
        do_request data: form_data

        expect(resource_object['number']).to eq new_phone['number']
        expect(response_status).to eq(200)
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

      example 'update phone number' do
        do_request data: form_data
        expect(resource_object['number']).to eq new_phone['number']
        expect(response_status).to eq(200)
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/phones/:id' do
      example_request 'delete phone number' do
        expect(response_status).to eq(200)
      end
    end
  end
end
