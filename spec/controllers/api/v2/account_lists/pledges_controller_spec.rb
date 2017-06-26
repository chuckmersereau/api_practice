require 'rails_helper'

RSpec.describe Api::V2::AccountLists::PledgesController, type: :controller do
  # This is required!
  let(:user) { create(:user_with_account) }

  let(:account_list) { user.account_lists.first }
  let(:contact) { create(:contact, account_list: account_list) }

  # This is required!
  let(:factory_type) { :pledge }

  # This is required!
  let!(:resource) do
    create(:pledge, account_list: account_list, contact: contact, amount: 9.99)
  end

  # This is required for the index action!
  let!(:second_resource) do
    create(:pledge, account_list: account_list, contact: contact, amount: 10.00)
  end

  # If needed, keep this ;)
  let(:id) { resource.uuid }

  # If needed, keep this ;)
  let(:parent_param) do
    { account_list_id: account_list.uuid }
  end

  # This is required!
  let(:correct_attributes) do
    { amount: 200.00, amount_currency: 'USD', expected_date: Date.today }
  end

  let(:correct_relationships) do
    {
      contact: {
        data: {
          id: contact.uuid,
          type: 'contacts'
        }
      }
    }
  end

  # This is required!
  let(:unpermitted_relationships) do
    {
      contact: {
        data: {
          id: create(:contact).uuid,
          type: 'contacts'
        }
      }
    }
  end

  # This is required!
  let(:incorrect_attributes) do
    { amount: 200.00, expected_date: nil }
  end

  # These includes can be found in:
  # spec/support/shared_controller_examples/*
  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
