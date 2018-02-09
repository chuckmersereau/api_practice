require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > People > Relationships' do
  include_context :json_headers
  documentation_scope = :people_api_relationships

  let(:resource_type) { :family_relationships }
  let!(:user)         { create(:user_with_full_account) }

  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.id }

  let(:person)    { create(:person, contacts: [contact]) }
  let(:person_id) { person.id }

  let!(:family_relationship) { create(:family_relationship, person: person) }
  let(:id)                   { family_relationship.id }

  let(:new_family_relationship) do
    attributes_for(:family_relationship)
      .reject { |key| key.to_s.end_with?('_id') }
      .merge(overwrite: true)
  end
  let(:relationships) do
    {
      person: {
        data: {
          type: 'people',
          id: person.id
        }
      },
      related_person: {
        data: {
          type: 'people',
          id: create(:person).id
        }
      }
    }
  end

  let(:form_data) { build_data(new_family_relationship, relationships: relationships) }

  let(:resource_associations) do
    %w(
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
      example 'Relationship [LIST]', document: documentation_scope do
        explanation 'List of Relationships associated to the Person'
        do_request

        expect(response_status).to eq 200
        check_collection_resource(1, %w(relationships))
      end
    end

    get '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at',        'Created At',       type: 'String'
        response_field 'updated_at',        'Updated At',       type: 'String'
        response_field 'updated_in_db_at',  'Updated In Db At', type: 'String'
      end

      example 'Relationship [GET]', document: documentation_scope do
        explanation 'The Person\'s Relationship with the given ID'
        do_request

        expect(response_status).to eq 200
        check_resource(%w(relationships))
      end
    end

    post '/api/v2/contacts/:contact_id/people/:person_id/relationships' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'relationship', 'Relationship'
      end

      example 'Relationship [CREATE]', document: documentation_scope do
        explanation 'Create a Relationship associated with the Person'
        do_request data: form_data

        expect(response_status).to eq 201
        expect(resource_object['relationship']).to eq new_family_relationship[:relationship]
      end
    end

    put '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter 'relationship',      'Relationship'
      end

      example 'Relationship [UPDATE]', document: documentation_scope do
        explanation 'Update the Person\'s Relationship with the given ID'
        do_request data: form_data

        expect(response_status).to eq 200
        expect(resource_object['relationship']).to eq new_family_relationship[:relationship]
      end
    end

    delete '/api/v2/contacts/:contact_id/people/:person_id/relationships/:id' do
      example 'Relationship [DELETE]', document: documentation_scope do
        explanation 'Delete the Person\'s Relationship with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
