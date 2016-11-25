require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::Contacts::PeopleController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:resource_type) { :person }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let!(:resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let!(:second_resource) { create(:person).tap { |person| create(:contact_person, contact: contact, person: person) } }
  let(:id) { resource.id }
  let(:parent_param) { { contact_id: contact.id } }
  let(:correct_attributes) { { first_name: 'Billy' } }
  let(:unpermitted_attributes) { nil }
  let(:incorrect_attributes) { nil }
  let(:factory_type) { :person }

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'
end
