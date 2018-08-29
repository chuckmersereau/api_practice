require 'rails_helper'
require 'rspec_api_documentation/dsl'
require Rails.root.join('app', 'seeders', 'notification_types_seeder.rb')

resource 'Constants' do
  include_context :json_headers
  documentation_scope = :entities_constants

  let(:user) { create(:user_with_account) }
  before { NotificationTypesSeeder.new.seed }
  before { api_login(user) }

  get '/api/v2/constants' do
    let(:resource_type) { 'constants' }

    let(:array_hash_value_keys) do
      %w(
        activity_hashes
        assignable_likely_to_give_hashes
        assignable_location_hashes
        assignable_send_newsletter_hashes
        assignable_status_hashes
        notification_hashes
        notification_translated_hashes
        pledge_currency_hashes
        pledge_frequency_hashes
        pledge_received_hashes
        send_appeals_hashes
        status_hashes
      )
    end

    let(:array_value_keys) do
      %w(
        activities
        assignable_likely_to_give
        assignable_locations
        assignable_send_newsletter
        assignable_statuses
        codes
        pledge_received
        statuses
      )
    end

    let(:hash_array_hash_value_keys) do
      %w(
        bulk_update_option_hashes
      )
    end

    let(:hash_array_value_keys) do
      %w(
        next_actions
        results
        sources
      )
    end

    let(:hash_hash_value_keys) do
      %w(
        locales
        organizations_attributes
        pledge_currencies
      )
    end

    let(:hash_value_keys) do
      %w(
        alert_frequencies
        dates
        languages
        mobile_alert_frequencies
        notifications
        organizations
        pledge_frequencies
      )
    end

    let(:key_collections) do
      %w(
        array_hash_value_keys
        array_value_keys
        hash_array_hash_value_keys
        hash_array_value_keys
        hash_hash_value_keys
        hash_value_keys
      )
    end

    let(:custom_keys) do
      %w(
        bulk_update_options
        csv_import
        tnt_import
      )
    end

    let(:keys) do
      keys = custom_keys
      key_collections.each do |key_collection|
        keys += send(key_collection)
      end
      keys
    end

    example 'List constants', document: documentation_scope do
      explanation 'List of Constants'
      do_request

      expect(response_status).to eq 200
      expect(resource_object.keys).to match_array keys

      expect(resource_object['bulk_update_options'].keys).to eq(
        %w(likely_to_give send_newsletter pledge_currency pledge_received status)
      )
      expect(resource_object['csv_import'].keys).to eq(
        %w(constants max_file_size_in_bytes required_headers supported_headers)
      )
      expect(resource_object['tnt_import'].keys).to eq(
        %w(max_file_size_in_bytes)
      )
      key_collections.each do |key_collection|
        send(key_collection).each do |key|
          object_type_tester(resource_object[key], key_collection)
        end
      end
    end
  end

  def object_type_tester(object, types)
    current, descendents = types.split('_', 2)
    send("#{current}?", object, descendents)
  end

  def array?(array, descendents)
    expect(array).to be_a(Array)
    array.each do |object|
      object_type_tester(object, descendents)
    end
  end

  def hash?(hash, descendents)
    expect(hash).to be_a(Hash)
    hash.each_value do |object|
      object_type_tester(object, descendents)
    end
  end

  def value?(value, _descendents)
    expect(%(TrueClass FalseClass NilClass String)).to include(value.class.name)
  end
end
