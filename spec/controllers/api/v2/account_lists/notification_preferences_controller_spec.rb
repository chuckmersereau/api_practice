require 'rails_helper'

RSpec.describe Api::V2::AccountLists::NotificationPreferencesController, type: :controller do
  let(:factory_type)            { :notification_preference }
  let!(:user)                   { create(:user_with_full_account) }
  let!(:account_list)           { user.account_lists.order(:created_at).first }
  let(:account_list_id)         { account_list.id }
  let(:notification_type)       { create(:notification_type) }
  let(:notification_type_1)     { create(:notification_type) }
  let(:notification_type_2)     { create(:notification_type) }
  let!(:notification_preferences) do
    [
      create(:notification_preference,
             account_list_id: account_list.id,
             email: true,
             task: true,
             notification_type_id: notification_type.id,
             user_id: user.id),
      create(:notification_preference,
             account_list_id: account_list.id,
             email: true,
             task: true,
             notification_type_id: notification_type_1.id,
             user_id: user.id,
             created_at: 1.week.from_now)
    ]
  end
  let(:correct_attributes) do
    {
      email: true,
      task: true
    }
  end
  let(:correct_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.id
        }
      },
      notification_type: {
        data: {
          type: 'notification_types',
          id: notification_type_2.id
        }
      }
    }
  end
  let(:resource)                { notification_preferences.first }
  let(:second_resource)         { notification_preferences.second }
  let!(:given_reference_key)    { :task }
  let(:id)                      { resource.id }
  let(:parent_param)            { { account_list_id: account_list.id } }
  let(:unpermitted_attributes)  { nil }
  let(:incorrect_attributes)    { nil }

  # These includes can be found in:
  # spec/support/shared_controller_examples/*
  include_examples 'index_examples', except: [:sorting]

  include_examples 'show_examples'

  include_examples 'create_examples', count: 2

  include_examples 'destroy_examples'
end
