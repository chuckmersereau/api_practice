require 'rails_helper'

describe Api::V2::Contacts::People::BulkController, type: :controller do
  let(:resource_type) { :people }
  let!(:factory_type) { :person }

  let!(:user) { create(:user_with_account) }

  let!(:account_list)    { user.account_lists.first }
  let!(:account_list_id) { account_list.uuid }

  let!(:id) { resource.uuid }

  let!(:resource)        { create(:person, contacts: [contact]) }
  let!(:second_resource) { create(:person, contacts: [contact]) }
  let!(:third_resource)  { create(:person, contacts: [contact]) }

  let!(:contact) { create(:contact, account_list: account_list) }

  let!(:incorrect_reference_value) { resource.send(reference_key) }
  let!(:given_reference_key)       { :first_name }
  let!(:given_reference_value)     { correct_attributes[:first_name] }

  let!(:correct_attributes) do
    attributes_for(:person, first_name: 'Michael', last_name: 'Bluth')
  end

  let!(:incorrect_attributes) do
    attributes_for(:person, first_name: nil)
  end

  let(:relationships) do
    {
      contacts: {
        data: [{
          type: 'contacts',
          id: contact.uuid
        }]
      }
    }
  end

  let(:forbidden_relationships) do
    {
      contacts: {
        data: [
          {
            type: 'contacts',
            id: create(:contact).uuid
          }
        ]
      }
    }
  end

  include_examples 'bulk_create_examples'

  # skipping forbidden resources as you can't update a person's contact relationship via bulk
  include_examples 'bulk_update_examples', except: [:forbidden_resources]

  include_examples 'bulk_destroy_examples'
end
