require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::EmailAddressesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  let(:account_list) { user.account_lists.first }
  let(:contact)      { create(:contact, account_list: account_list) }
  let(:person)       { create(:person, contacts: [contact]) }

  # This is required!
  let(:factory_type) do
    # This is the type used to auto-generate a resource using FactoryGirl,
    # ex: The type `:email_address` would be used as create(:email_address)
    :email_address
  end

  # This is required!
  let!(:resource) do
    # Creates the Singular Resource for this spec - change as needed
    # Example: create(:contact, account_list: account_list)
    create(:email_address, person: person)
  end

  let!(:second_resource) do
    create(:email_address, person: person)
  end

  # If needed, keep this ;)
  let(:id) { resource.uuid }

  # If needed, keep this ;)
  let(:parent_param) do
    # This is a hash of the nested keys needed for the URL,
    # If the resource is listed more than once, you can add multiple.
    # Ex: /api/v2/:account_list_id/contacts/:contact_id/addresses/:id
    # --
    # Note: Don't include :id
    # Example: { account_list_id: account_list_id }
    {
      contact_id: contact.uuid,
      person_id: person.uuid
    }
  end

  # This is required!
  let(:correct_attributes) do
    # A hash of correct attributes for creating/updating the resource
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: account_list.uuid }
    {
      email: 'test@example.com',
      historic: false,
      location: 'mobile',
      primary: true
    }
  end

  # This is required!
  let(:unpermitted_attributes) do
    # A hash of attributes that include unpermitted attributes for the current user to update
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: create(:account_list).uuid } }
    # --
    # If there aren't attributes that are unpermitted,
    # you need to specifically return `nil`
    #
    # The only case where you would need to _not_ return `nil` is if you are creating or updating
    # a resource that has `account_list` as a foreign key that is not already nested under
    # the account list controller namespace. Ex: Contact

    nil
  end

  # This is required!
  let(:incorrect_attributes) do
    # A hash of attributes that will fail validations
    # Example: { subject: nil, account_list_id: account_list.uuid } }
    # --
    # If there aren't attributes that violate validations,
    # you need to specifically return `nil`
    {
      email: 'INVALID_EMAIL!!!!!!!',
      historic: false,
      location: 'mobile',
      primary: true
    }
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples.rb
  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end