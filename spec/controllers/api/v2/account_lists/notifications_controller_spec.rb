require 'spec_helper'

describe Api::V2::AccountLists::NotificationsController, type: :controller do
  let(:resource_type) { :notification }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:notifications) { create_list(:notification, 2, contact: contact) }
  let(:notification) { notifications.first }
  let(:id) { notification.id }

  let(:resource) { notification }
  let(:parent_path) { { account_list_id: account_list_id } }
  let(:correct_attributes) { attributes_for(:notification, contact: contact, notification_type_id: 2) }
  let(:incorrect_attributes) { { event_date: nil, notification_type_id: 2 } }

  include_examples 'index_examples'

  include_examples 'show_examples'

  include_examples 'create_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'
end
