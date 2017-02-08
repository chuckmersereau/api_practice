require 'rails_helper'
require 'rspec_api_documentation/dsl'
require Rails.root.join('db', 'seeders', 'notification_types_seeder.rb')

resource 'Constants' do
  include_context :json_headers

  let(:user) { create(:user_with_account) }

  context 'authorized user' do
    before { NotificationTypesSeeder.new.seed }
    before { api_login(user) }

    # Activities
    get '/api/v2/constants' do
      let(:resource_type) { 'constants' }

      let(:contact_attribute_keys) do
        %w(
          assignable_likely_to_give
          assignable_send_newsletter
          statuses
        )
      end

      let(:expected_attribute_keys) do
        %w(
          activities
          currencies
          locales
          notifications
          organizations
          pledge_currencies
          pledge_frequencies
        ) + contact_attribute_keys
      end

      example 'Constant [LIST]', document: :entities do
        explanation 'List of Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['activities'].each do |activity|
          expect(activity).to be_a(String)
        end

        resource_object['currencies'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(String)
        end

        resource_object['locales'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(String)
        end

        resource_object['notifications'].each do |notification|
          expect(notification.size).to eq 2
          expect(notification.first).to be_a(String)
          expect(notification.second).to be_a(String)
        end

        resource_object['organizations'].each do |organization|
          expect(organization.size).to eq 2
          expect(organization.first).to be_a(String)
          expect(organization.second).to be_a(String)
        end

        resource_object['pledge_frequencies'].each do |frequency|
          expect(frequency.size).to eq 2
          expect(frequency.first).to be_a(String)
          expect(frequency.second).to be_a(String)
        end

        resource_object['pledge_currencies'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(String)
        end

        contact_attribute_keys.each do |key|
          resource_object[key].each do |val|
            expect(val).to be_a(String)
          end
        end
      end
    end
  end
end
