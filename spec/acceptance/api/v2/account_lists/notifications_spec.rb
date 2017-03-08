require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Notifications' do
  include_context :json_headers
  documentation_scope = :account_lists_api_notifications

  let(:resource_type) { 'notifications' }
  let!(:user)         { create(:user_with_full_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:contact)        { create(:contact, account_list: account_list) }
  let!(:notifications)  { create_list(:notification, 2, contact: contact) }
  let(:notification)    { notifications.first }
  let(:id)              { notification.uuid }
  let(:donation)        { create(:donation) }

  let(:new_notification) do
    attributes_for(:notification)
      .reject { |attr| attr.to_s.end_with?('_id') }
      .merge(updated_in_db_at: notification.updated_at)
  end

  let(:form_data) do
    build_data(new_notification, relationships: relationships)
  end

  let(:relationships) do
    {
      contact: {
        data: {
          type: 'contacts',
          id: contact.uuid
        }
      },
      donation: {
        data: {
          type: 'donations',
          id: donation.uuid
        }
      },
      notification_type: {
        data: {
          type: 'notification_types',
          id: notification.notification_type.uuid
        }
      }
    }
  end

  let(:resource_attributes) do
    %w(
      cleared
      created_at
      event_date
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
      response_field 'data',       'Data', type: 'Array[Object]'

      example 'Notification [LIST]', document: documentation_scope do
        explanation 'List of Notifications associated with the Account List'
        do_request
        check_collection_resource(2, ['relationships'])
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/notifications/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'cleared',              'Cleared',              type: 'Boolean'
        response_field 'contact_id',           'Contact ID',           type: 'Number'
        response_field 'created_at',           'Created At',           type: 'String'
        response_field 'donation_id',          'Donation ID',          type: 'Number'
        response_field 'event_date',           'Event Date',           type: 'String'
        response_field 'notification_type_id', 'Notification Type ID', type: 'Number'
        response_field 'updated_at',           'Updated At',           type: 'String'
        response_field 'updated_in_db_at',     'Updated In Db At',     type: 'String'
      end

      example 'Notification [GET]', document: documentation_scope do
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

      example 'Notification [CREATE]', document: documentation_scope do
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

      example 'Notification [UPDATE]', document: documentation_scope do
        explanation 'Updates the Account List Notification with the given ID'
        do_request data: form_data

        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/notifications/:id' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'ID', required: true

      example 'Notification [DELETE]', document: documentation_scope do
        explanation 'Deletes the Account List Notification with the given ID'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
