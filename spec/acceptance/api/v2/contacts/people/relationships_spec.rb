require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Relationship' do
  include_context :json_headers

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

  let(:resource_associations) do
    %w(
      person
      related_person
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships' do
      example 'Person / Relationship [LIST]', document: :contacts do
        do_request
        explanation 'List of Relationships associated to the person'
        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'person_id',         'Person Id',      'Type' => 'Number'
        response_field 'related_person_id', 'Related Person', 'Type' => 'Number'
        response_field 'relationship',      'Relationship',   'Type' => 'String'
      end

      example 'Person / Relationship [GET]', document: :contacts do
        do_request
        check_resource(['relationships'])
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

      example 'Person / Relationship [UPDATE]', document: :contacts do
        do_request data: form_data

        expect(resource_object['username']).to eq new_family_relationship['username']
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      example 'Person / Relationship [DELETE]', document: :contacts do
        do_request
        expect(response_status).to eq 200
      end
    end
  end
end
