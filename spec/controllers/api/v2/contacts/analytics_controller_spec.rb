require 'spec_helper'

RSpec.describe Api::V2::Contacts::AnalyticsController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.first }

  let!(:contact_with_anniversary_with_week) do
    person = create(:person, anniversary_month: Date.current.month,
                             anniversary_day: Date.current.day)

    contact = create(:contact, account_list_id: account_list.id,
                               status: 'Partner - Financial')

    contact.people << person
    contact
  end

  let!(:contact_with_birthday_this_week) do
    person = create(:person, birthday_month: Date.current.month,
                             birthday_day: Date.current.day)

    contact = create(:contact, account_list_id: account_list.id,
                               status: 'Partner - Financial')

    contact.people << person
    contact
  end

  # This is required!
  let!(:resource) do
    # Creates the Singular Resource for this spec - change as needed
    # Example: create(:contact, account_list: account_list)
    Contact::Analytics.new(user.contacts)
  end

  # If needed, keep this ;)
  let(:parent_param) do
    # This is a hash of the nested keys needed for the URL,
    # If the resource is listed more than once, you can add multiple.
    # Ex: /api/v2/:account_list_id/contacts/:contact_id/addresses/:id
    # --
    # Note: Don't include :id
    # Example: { account_list_id: account_list_id }
    {}
  end

  # This is required!
  let(:correct_attributes) do
    # A hash of correct attributes for creating/updating the resource
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: account_list.id }
    {}
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples.rb
  include_examples 'show_examples'
end
