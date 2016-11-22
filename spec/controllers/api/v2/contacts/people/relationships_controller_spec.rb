require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::Contacts::People::RelationshipsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :family_relationship }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let(:person) { create(:person, contacts: [contact]) }
  let!(:resource) { create(:family_relationship, person: person) }
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id, person_id: person.id } }
  let(:correct_attributes) { { relationship: 'Father', person_id: person.id, related_person_id: create(:person).id } }
  let(:unpermitted_attributes) { { relationship: 'test relationship', person_id: create(:person).id, related_person_id: create(:person).id } }
  let(:incorrect_attributes) { { relationship: nil } }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
