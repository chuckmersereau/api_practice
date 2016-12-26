require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Relationship' do
  include_context :json_headers

  let(:resource_type) { 'family_relationships' }
  let!(:user)         { create(:user_with_full_account) }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.uuid }

  let(:person)    { create(:person, contacts: [contact]) }
  let(:person_id) { person.uuid }

  let!(:family_relationship) { create(:family_relationship, person: person) }
  let(:id)                   { family_relationship.uuid }

  let(:new_family_relationship) do
    build(:family_relationship).attributes.merge(related_person_id: create(:person).uuid,
                                                 updated_in_db_at: family_relationship.updated_at,
                                                 person_id: person.uuid)
  end
  let(:form_data) { build_data(new_family_relationship) }

  let(:resource_associations) do
    %w(
      person
      related_person
    )
  end

  let(:resource_attributes) do
    %w(
      created_at
      relationship
      updated_at
      updated_in_db_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships' do
      example 'Person / Relationship [LIST]', document: :contacts do
        explanation 'List of Relationships associated to the Person'
        do_request
        check_collection_resource(1, %w(relationships))
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',        'Created At',       'Type' => 'String'
        response_field 'person_id',         'Person Id',        'Type' => 'Number'
        response_field 'updated_at',        'Updated At',       'Type' => 'String'
        response_field 'updated_in_db_at',  'Updated In Db At', 'Type' => 'String'
      end

      example 'Person / Relationship [GET]', document: :contacts do
        explanation 'The Person\'s Relationship with the given ID'
        do_request
        check_resource(%w(relationships))
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/relationships' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'person_id',         'Person Id'
        parameter 'related_person_id', 'Related Person Id'
        parameter 'relationship',      'Relationship'
      end

      example 'Person / Relationship [CREATE]', document: :contacts do
        explanation 'Create a Relationship associated with the Person'
        do_request data: form_data
        expect(resource_object['relationship']).to eq new_family_relationship['relationship']
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'person_id',         'Person Id'
        parameter 'related_person_id', 'Related Person Id'
        parameter 'relationship',      'Relationship'
      end

      example 'Person / Relationship [UPDATE]', document: :contacts do
        explanation 'Update the Person\'s Relationship with the given ID'
        do_request data: form_data

        expect(resource_object['relationship']).to eq new_family_relationship['relationship']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      example 'Person / Relationship [DELETE]', document: :contacts do
        explanation 'Delete the Person\'s Relationship with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
