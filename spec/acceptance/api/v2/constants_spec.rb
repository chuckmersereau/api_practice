require 'rails_helper'
require 'rspec_api_documentation/dsl'
require Rails.root.join('db', 'seeders', 'notification_types_seeder.rb')

resource 'Constants' do
  include_context :json_headers
  documentation_scope = :entities_constants

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
          alert_frequencies
          assignable_locations
          assignable_statuses
          bulk_update_options
          csv_import
          dates
          languages
          locales
          mobile_alert_frequencies
          next_actions
          notifications
          organizations
          organizations_attributes
          pledge_currencies
          pledge_frequencies
          results
          sources
          tnt_import
        ) + contact_attribute_keys
      end

      example 'List constants', document: documentation_scope do
        explanation 'List of Constants'
        do_request

        expect(response_status).to eq 200
        expect(resource_object.keys).to match_array expected_attribute_keys

        resource_object['activities'].each do |activity|
          expect(activity).to be_a(String)
        end

        expect(resource_object['csv_import'].keys.size).to eq 4

        expect(resource_object['tnt_import'].keys.size).to eq 1

        resource_object['dates'].each do |date_format|
          expect(date_format.size).to eq 2
          expect(date_format.first).to be_a(String)
          expect(date_format.second).to be_a(String)
        end

        resource_object['languages'].each do |language|
          expect(language.size).to eq 2
          expect(language.first).to be_a(String)
          expect(language.second).to be_a(String)
        end

        resource_object['locales'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(Hash)
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

        resource_object['organizations_attributes'].each do |organization_attributes|
          expect(organization_attributes.size).to eq 2
          expect(organization_attributes.first).to be_a(String)
          expect(organization_attributes.second).to be_a(Hash)
        end

        resource_object['pledge_frequencies'].each do |frequency|
          expect(frequency.size).to eq 2
          expect(frequency.first).to be_a(String)
          expect(frequency.second).to be_a(String)
        end

        resource_object['pledge_currencies'].each do |currency|
          expect(currency.size).to eq 2
          expect(currency.first).to be_a(String)
          expect(currency.second).to be_a(Hash)
        end

        expect(resource_object['sources'].size).to eq 3
        resource_object['sources'].each do |source|
          expect(source.second).to be_a(Array)
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
