require 'rails_helper'

describe Api::V2::AccountListsController, type: :controller do
  let(:factory_type) { :account_list }
  let!(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let!(:second_account_list) { create(:account_list, users: [user], created_at: 2.weeks.from_now) }
  let(:id) { account_list.id }

  let(:resource) { account_list }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { attributes_for(:account_list) }
  let(:incorrect_attributes) { { name: nil } }

  let!(:notification_preference) { create(:notification_preference, account_list: account_list) }

  let(:correct_relationships) do
    {
      notification_preferences: {
        data: {
          type: 'notification_preferences',
          id: create(:notification_preference).id
        }
      }
    }
  end

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'
end
