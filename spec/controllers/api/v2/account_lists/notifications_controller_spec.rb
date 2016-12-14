require 'spec_helper'

describe Api::V2::AccountLists::NotificationsController, type: :controller do
  let(:factory_type) { :notification }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:notifications) { create_list(:notification, 2, contact_id: contact.id) }
  let(:notification) { notifications.first }
  let(:notification_type) { create(:notification_type) }
  let(:id) { notification.uuid }

  let(:resource) { notification }
  let(:parent_param) { { account_list_id: account_list.uuid } }
  let(:unpermitted_attributes) { nil }
  let(:correct_attributes) { { cleared: true, event_date: Time.now, notification_type_id: notification_type.uuid, contact_id: contact.uuid } }
  let(:incorrect_attributes) { { event_date: nil, notification_type_id: notification_type.uuid } }
  let(:reference_key) { :event_date }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
