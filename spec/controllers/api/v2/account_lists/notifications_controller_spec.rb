require 'spec_helper'

describe Api::V2::AccountLists::NotificationsController, type: :controller do
  let(:factory_type) { :notification }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:notifications) { create_list(:notification, 2, contact: contact) }
  let(:notification) { notifications.first }
  let(:notification_type) { create(:notification_type) }
  let(:id) { notification.uuid }

  let(:resource) { notification }
  let(:parent_param) { { account_list_id: account_list_id } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { cleared: true, event_date: Time.now, notification_type_id: notification_type.uuid } }
  let(:incorrect_attributes) { { event_date: nil, notification_type_id: notification_type.uuid } }
  let(:reference_key) { :event_date }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
