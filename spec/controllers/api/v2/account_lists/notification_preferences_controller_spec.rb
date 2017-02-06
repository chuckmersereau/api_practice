require 'spec_helper'

RSpec.describe Api::V2::AccountLists::NotificationPreferencesController, type: :controller do
  let(:factory_type) { :notification_preference }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:notification_preferences) do
    create_list(:notification_preference, 2,
                account_list_id: account_list.id,
                actions: 'email',
                notification_type: notification_type)
  end
  let(:notification_preference) { notification_preferences.first }
  let(:notification_type) { create(:notification_type) }
  let(:id) { notification_preference.uuid }

  let(:resource) { notification_preference }
  let(:parent_param) { { account_list_id: account_list.uuid } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { actions: 'email', account_list_id: account_list.uuid, notification_type_id: notification_type.uuid } }
  let(:incorrect_attributes) { nil }
  let!(:second_resource) { notification_preferences.second }

  # These includes can be found in:
  # spec/support/shared_controller_examples/*
  include_examples 'index_examples', except: [:sorting]

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'destroy_examples'
end
