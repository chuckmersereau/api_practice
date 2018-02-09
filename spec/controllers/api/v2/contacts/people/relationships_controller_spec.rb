require 'rails_helper'

RSpec.describe Api::V2::Contacts::People::RelationshipsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :family_relationship }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let(:person) { create(:person, contacts: [contact]) }
  let!(:resource) { create(:family_relationship, person: person) }
  let!(:second_resource) { create(:family_relationship, person: person) }
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id, person_id: person.id } }
  let(:correct_attributes) { { relationship: 'Father' } }

  let(:correct_relationships) do
    {
      related_person: {
        data: {
          type: 'people',
          id: create(:person, contacts: [contact]).id
        }
      }
    }
  end

  let(:incorrect_attributes) { { relationship: nil } }
  let(:incorrect_relationships) { {} }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
