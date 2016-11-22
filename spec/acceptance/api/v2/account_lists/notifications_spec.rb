require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Notifications' do
  let(:resource_type) { 'notifications' }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:contact) { create(:contact, account_list_id: account_list.id) }
  let!(:notifications) { create_list(:notification, 2, contact: contact) }
  let(:notification) { notifications.first }
  let(:id) { notification.id }
  let(:new_notification) { build(:notification).attributes }
  let(:form_data) { build_data(new_notification) }
  let(:expected_attribute_keys) { %w(contact-id notification-type-id event-date cleared donation-id) }

  context 'authorized user' do
    before do
      api_login(user)
    end
    get '/api/v2/account_lists/:account_list_id/notifications' do
      parameter 'account-list-id',              'Account List ID', required: true
      response_field :data,                     'Data', 'Type' => 'Array[Object]'
      example_request 'list notifications of account list' do
        check_collection_resource(2, ['relationships'])
        expect(resource_object.keys).to eq expected_attribute_keys
        expect(status).to eq 200
      end
    end
    get '/api/v2/account_lists/:account_list_id/notifications/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'event-date',              'Event Date', 'Type' => 'String'
        response_field 'contact-id',              'Contact ID', 'Type' => 'Number'
        response_field 'notification-type-id',    'Notification Type ID', 'Type' => 'Number'
        response_field :cleared,                  'Cleared', 'Type' => 'Boolean'
        response_field 'donation-id',             'Donation ID', 'Type' => 'Number'
      end
      example_request 'get notification' do
        check_resource(['relationships'])
        expect(resource_object.keys).to eq expected_attribute_keys
        expect(status).to eq 200
      end
    end
    post '/api/v2/account_lists/:account_list_id/notifications' do
      with_options scope: [:data, :attributes] do
        parameter :cleared,                       'Cleared'
        parameter 'event-date',                   'Event Date'
        parameter 'contact-id',                   'Contact ID'
        parameter 'notification-type-id',         'Notification Type ID'
        parameter 'donation-id',                  'Donation ID'
      end
      example 'create notification' do
        do_request data: form_data
        expect(status).to eq 200
      end
    end
    put '/api/v2/account_lists/:account_list_id/notifications/:id' do
      with_options scope: [:data, :attributes] do
        parameter :cleared,                       'Cleared'
        parameter 'event-date',                   'Event Date'
        parameter 'contact-id',                   'Contact ID'
        parameter 'notification-type-id',         'Notification Type ID'
        parameter 'donation-id',                  'Donation ID'
      end
      example 'update notification' do
        do_request data: form_data
        expect(status).to eq 200
      end
    end
    delete '/api/v2/account_lists/:account_list_id/notifications/:id' do
      parameter 'account-list-id',              'Account List ID', required: true
      parameter 'id',                           'ID', required: true
      example_request 'delete notification' do
        expect(status).to eq 200
      end
    end
  end
end
