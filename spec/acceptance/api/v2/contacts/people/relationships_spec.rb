require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Relationship' do
  header 'Content-Type', 'application/vnd.api+json'

  let(:resource_type) { 'family_relationships' }
  let!(:user)         { create(:user_with_full_account) }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.id }

  let(:person)    { create(:person, contacts: [contact]) }
  let(:person_id) { person.id }

  let!(:family_relationship) { create(:family_relationship, person: person) }
  let(:id)                   { family_relationship.id }

  let(:new_family_relationship) { build(:family_relationship, person: person).attributes }
  let(:form_data)               { build_data(new_family_relationship) }

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships' do
      example_request 'get relationships' do
        explanation 'List of Relationships associated to the person'
        check_collection_resource(1)
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'person_id',         'Person Id',      'Type' => 'Number'
        response_field 'related_person_id', 'Related Person', 'Type' => 'Number'
        response_field 'relationship',      'Relationship',   'Type' => 'String'
      end

      example_request 'get organization account' do
        check_resource
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/relationships' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'person_id',         'Person Id'
        parameter 'related_person_id', 'Related Person Id'
        parameter 'relationship',      'Relationship'
      end

      example 'create organization account' do
        do_request data: form_data
        expect(resource_object['username']).to eq new_family_relationship['username']
        expect(response_status).to eq 200
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'person_id',         'Person Id'
        parameter 'related_person_id', 'Related Person Id'
        parameter 'relationship',      'Relationship'
      end

      example 'update notification' do
        do_request data: form_data

        expect(resource_object['username']).to eq new_family_relationship['username']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      example_request 'delete notification' do
        expect(response_status).to eq 200
      end
    end
  end
end
