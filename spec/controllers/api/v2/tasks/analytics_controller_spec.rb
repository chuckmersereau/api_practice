require 'rails_helper'

RSpec.describe Api::V2::Tasks::AnalyticsController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  # This MAY be required!
  let(:account_list) { user.account_lists.order(:created_at).first }

  # This is required!
  let!(:resource) do
    # Creates the Singular Resource for this spec - change as needed
    # Example: create(:contact, account_list: account_list)
    Task::Analytics.new(user.tasks)
  end

  # If needed, keep this ;)
  let(:parent_param) do
    # This is a hash of the nested keys needed for the URL,
    # If the resource is listed more than once, you can add multiple.
    # Ex: /api/v2/:account_list_id/contacts/:contact_id/addresses/:id
    # --
    # Note: Don't include :id
    # Example: { account_list_id: account_list.id }
    {}
  end

  # This is required!
  let(:correct_attributes) do
    # A hash of correct attributes for creating/updating the resource
    # Example: { subject: 'test subject', start_at: Time.now, account_list_id: account_list.id }
    {}
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples

  include_examples 'show_examples', except: [:sparse_fieldsets]
end
