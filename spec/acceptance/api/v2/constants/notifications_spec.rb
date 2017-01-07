require 'spec_helper'
require 'rspec_api_documentation/dsl'
require Rails.root.join('db', 'seeders', 'notification_types_seeder.rb')

resource 'Notifications' do
  include_context :json_headers

  let(:resource_type) { 'notifications' }
  let(:user) { create(:user_with_account) }

  let(:expected_attribute_keys) do
    %w(
      notifications
    )
  end

  context 'authorized user' do
    before { api_login(user) }
    before { NotificationTypesSeeder.new.seed }

    # index
    get '/api/v2/constants/notifications' do
      example 'Notification [LIST]', document: :constants do
        explanation 'List of Notification Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['notifications'].each do |notification|
          expect(notification.size).to eq 2
          expect(notification.first).to be_a(String)
          expect(notification.second).to be_a(Fixnum)
        end
      end
    end
  end
end
