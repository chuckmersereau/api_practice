require 'rails_helper'

RSpec.describe Api::V2::Contacts::DuplicatesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.first }

  # This is required!
  let(:factory_type) do
    # This is the type used to auto-generate a resource using FactoryGirl,
    # ex: The type `:email_address` would be used as create(:email_address)
    :contact
  end

  # The minimum number of records for having two separate contact duplicates
  let(:person1) { create(:person, first_name: 'john', last_name: 'doe') }
  let(:person2) { create(:person, first_name: 'John', last_name: 'Doe') }
  let(:person3) { create(:person, first_name: 'jane', last_name: 'doe') }
  let(:person4) { create(:person, first_name: 'Jane', last_name: 'Doe') }
  let(:contact1) { create(:contact, name: 'Doe, John 1', account_list: account_list) }
  let(:contact2) { create(:contact, name: 'Doe, John 2', account_list: account_list) }
  let(:contact3) { create(:contact, name: 'Doe, Jane 1', account_list: account_list) }
  let(:contact4) { create(:contact, name: 'Doe, Jane 2', account_list: account_list) }

  # This is required!
  let!(:resource) do
    Contact::Duplicate.new(contact3, contact4)
  end

  # This is required for the index action!
  let!(:second_resource) do
    Contact::Duplicate.new(contact3, contact4)
  end

  # If needed, keep this ;)
  let(:id) { resource.id }

  let(:count) { -> { Contact::DuplicatesFinder.new(account_list).find.count } }

  # If needed, keep this ;)
  # let(:parent_param) do
  #   # This is a hash of the nested keys needed for the URL,
  #   # If the resource is listed more than once, you can add multiple.
  #   # Ex: /api/v2/:account_list_id/contacts/:contact_id/addresses/:id
  #   # --
  #   # Note: Don't include :id
  #   # Example: { account_list_id: account_list.uuid }
  # end

  # This is required!
  let(:correct_attributes) do
    # A hash of correct attributes for creating/updating the resource
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: account_list.id }
    {}
  end

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
    nil
  end

  before(:each) do
    contact1.people << person1
    contact2.people << person2
    contact3.people << person3
    contact4.people << person4
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples.rb
  include_examples 'index_examples', except: [:sparse_fieldsets, :sorting]
  #
  # include_examples 'show_examples'
  #
  # include_examples 'create_examples'
  #
  # include_examples 'update_examples'
  #
  include_examples 'destroy_examples'
end
