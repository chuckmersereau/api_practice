require 'rails_helper'

RSpec.describe Api::V2::Contacts::ReferralsController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.first }

  let(:contact)          { create(:contact, account_list: account_list) }
  let(:contact_referred) { create(:contact, account_list: account_list) }
  let(:alternate)        { create(:contact, account_list: account_list) }

  # This is required!
  let(:factory_type) do
    # This is the type used to auto-generate a resource using FactoryGirl,
    # ex: The type `:email_address` would be used as create(:email_address)
    :contact_referral
  end

  # This is required!
  let!(:resource) do
    # Creates the Singular Resource for this spec - change as needed
    # Example: create(:contact, account_list: account_list)
    attributes = {
      referred_by: contact,
      referred_to: contact_referred
    }

    create(:contact_referral, attributes)
  end

  # This is required for the index action!
  let!(:second_resource) do
    # Creates a second resource for this spec - change as needed
    # Example: create(:contact, account_list: account_list)
    attributes = {
      referred_by: contact,
      referred_to: contact_referred
    }

    create(:contact_referral, attributes)
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
      contact_id: contact.uuid
    }
  end

  # This is required!
  let(:correct_attributes) do
    # A hash of correct attributes for creating/updating the resource
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: account_list.id }
    {}
  end

  let(:correct_relationships) do
    {
      referred_by: {
        data: {
          type: 'contacts',
          id: contact.uuid
        }
      },
      referred_to: {
        data: {
          type: 'contacts',
          id: contact_referred.uuid
        }
      }
    }
  end

  # This is only required if you need your update attributes to be different
  # than the value of correct_attributes.
  #
  # If you don't need it - remove it entirely.
  let(:update_attributes) do
    {
      updated_in_db_at: contact_referred.updated_at
    }
  end

  let(:update_relationships) do
    {
      referred_to: {
        data: {
          type: 'contacts',
          id: alternate.uuid
        }
      }
    }
  end
  let(:given_reference_key) { nil }
  let(:given_update_reference_key) { :referred_to_id }
  let(:given_update_reference_value) { alternate.id }

  # This is required!
  let(:unpermitted_attributes) do
    # A hash of attributes that include unpermitted attributes for the current user to update
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: create(:account_list).id } }
    # --
    # If there aren't attributes that are unpermitted,
    # you need to specifically return `nil`

    nil
  end

  # This is required!
  let(:incorrect_attributes) do
    # A hash of attributes that will fail validations
    # Example: { subject: nil, account_list_id: account_list.id } }
    # --
    # If there aren't attributes that violate validations,
    # you need to specifically return `nil`
    #
    {}
  end

  let(:incorrect_relationships) do
    {}
  end

  let(:dont_run_incorrect_update) { true }

  # These includes can be found in:
  # spec/support/shared_controller_examples.rb
  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
