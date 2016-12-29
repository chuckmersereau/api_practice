require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Notifications' do
  include_context :json_headers

  let(:resource_type) { 'notifications' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:contact)        { create(:contact, account_list: account_list) }
  let!(:notifications)  { create_list(:notification, 2, contact: contact) }
  let(:notification)    { notifications.first }
  let(:id)              { notification.uuid }

  let(:new_notification) do
    build(:notification).attributes.merge(updated_in_db_at: notification.updated_at)
                        .except('notification_type_id')
  end
  let(:form_data) { build_data(new_notification) }

  let(:resource_attributes) do
    %w(
      cleared
      contact_id
      created_at
      donation_id
      event_date
      notification_type_id
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      contact
      donation
      notification_type
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/notifications' do
      parameter 'account_list_id', 'Account List ID', required: true
      response_field 'data',       'Data', 'Type' => 'Array[Object]'

      example 'Notification [LIST]', document: :account_lists do
        explanation 'List of Notifications associated with the Account List'
        do_request
        check_collection_resource(2, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/notifications/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'cleared',              'Cleared',              'Type' => 'Boolean'
        response_field 'contact_id',           'Contact ID',           'Type' => 'Number'
        response_field 'created_at',           'Created At',           'Type' => 'String'
        response_field 'donation_id',          'Donation ID',          'Type' => 'Number'
        response_field 'event_date',           'Event Date',           'Type' => 'String'
        response_field 'notification_type_id', 'Notification Type ID', 'Type' => 'Number'
        response_field 'updated_at',           'Updated At',           'Type' => 'String'
        response_field 'updated_in_db_at',     'Updated In Db At',     'Type' => 'String'
      end

      example 'Notification [GET]', document: :account_lists do
        explanation 'The Account List Notification with the given ID'
        do_request
        check_resource(['relationships'])
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/account_lists/:account_list_id/notifications' do
      with_options scope: [:data, :attributes] do
        parameter 'cleared',              'Cleared'
        parameter 'contact_id',           'Contact ID'
        parameter 'donation_id',          'Donation ID'
        parameter 'event_date',           'Event Date'
        parameter 'notification_type_id', 'Notification Type ID'
      end

      example 'Notification [CREATE]', document: :account_lists do
        explanation 'Creates a new Notification associated with the Account List'
        do_request data: form_data
        expect(response_status).to eq 201
      end
    end

    put '/api/v2/account_lists/:account_list_id/notifications/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'cleared',              'Cleared'
        parameter 'contact_id',           'Contact ID'
        parameter 'donation_id',          'Donation ID'
        parameter 'event_date',           'Event Date'
        parameter 'notification_type_id', 'Notification Type ID'
      end

      example 'Notification [UPDATE]', document: :account_lists do
        explanation 'Updates the Account List Notification with the given ID'
        do_request data: form_data
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/notifications/:id' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'ID', required: true

      example 'Notification [DELETE]', document: :account_lists do
        explanation 'Deletes the Account List Notification with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
