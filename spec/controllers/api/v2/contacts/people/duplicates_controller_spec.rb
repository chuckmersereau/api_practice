require 'spec_helper'

RSpec.describe Api::V2::Contacts::People::DuplicatesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.first }

  # This is required!
  let(:factory_type) do
    # This is the type used to auto-generate a resource using FactoryGirl,
    # ex: The type `:email_address` would be used as create(:email_address)
    :person
  end

  # The minimum number of records for having two separate contact duplicates
  let(:person1) { create(:person, first_name: 'John', last_name: 'Doe') }
  let(:person2) { create(:person, first_name: 'john', last_name: 'doe') }
  let(:person3) { create(:person, first_name: 'Jane', last_name: 'Doe') }
  let(:person4) { create(:person, first_name: 'jane', last_name: 'doe') }
  let(:contact1) { create(:contact, name: 'Doe, John', account_list: account_list) }
  let(:contact2) { create(:contact, name: 'Doe, Jane', account_list: account_list) }

  # This is required!
  let!(:resource) do
    Person::Duplicate.new(
      person: person1,
      dup_person: person2,
      shared_contact: contact1
    )
  end

  # This is required for the index action!
  let!(:second_resource) do
    Person::Duplicate.new(
      person: person3,
      dup_person: person4,
      shared_contact: contact2
    )
  end

  # If needed, keep this ;)
  let(:id) { resource.id }

  let(:count) { -> { Person::DuplicatesFinder.new(account_list).find.count } }

  # This is required!
  let(:correct_attributes) do
    {}
  end

  # This is required!
  let(:unpermitted_attributes) do
    nil
  end

  # This is required!
  let(:incorrect_attributes) do
    nil
  end

  before(:each) do
    contact1.people << person1
    contact1.people << person2
    contact2.people << person3
    contact2.people << person4
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples.rb
  include_examples 'index_examples', except: [:sparse_fieldsets, :sorting]

  include_examples 'destroy_examples'
end
