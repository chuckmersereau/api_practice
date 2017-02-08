require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contact Analytics' do
  include_context :json_headers

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'contact_analytics' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:alternate_account_list) do
    create(:account_list).tap do |account_list|
      user.account_lists << account_list
    end
  end

  let(:contact_with_anniversary_with_week) do
    create(:contact, account_list_id: account_list.id,
                     status: 'Partner - Financial')
  end

  let(:person_with_anniversary_this_week) do
    create(:person, anniversary_month: Date.current.month,
                    anniversary_day: Date.current.day)
  end

  let(:contact_with_birthday_this_week) do
    create(:contact, account_list_id: account_list.id,
                     status: 'Partner - Financial')
  end

  let(:contact_with_birthday_this_week_but_different_account_list) do
    create(:contact, account_list_id: alternate_account_list.id,
                     status: 'Partner - Financial')
  end

  let(:person_with_birthday_this_week) do
    create(:person, birthday_month: Date.current.month,
                    birthday_day: Date.current.day)
  end

  let(:person_with_birthday_this_week_from_different_account_list) do
    create(:person, birthday_month: Date.current.month,
                    birthday_day: Date.current.day)
  end

  let(:birthday_relationship_data) do
    json_response['data']['relationships']['birthdays_this_week']['data']
  end

  let(:anniversary_relationship_data) do
    json_response['data']['relationships']['anniversaries_this_week']['data']
  end

  before do
    contact_with_birthday_this_week
      .people << person_with_birthday_this_week

    contact_with_birthday_this_week_but_different_account_list
      .people << person_with_birthday_this_week_from_different_account_list

    contact_with_anniversary_with_week
      .people << person_with_anniversary_this_week
  end

  let(:expected_attribute_keys) do
    # list your expected resource keys vertically here (alphabetical please!)
    %w(
      created_at
      first_gift_not_received_count
      partners_30_days_late_count
      partners_60_days_late_count
      updated_at
      updated_in_db_at
    )
  end

  let(:additional_attribute_keys) do
    %w(
      relationships
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    context 'without specifying an `account_list_id`' do
      # show
      get '/api/v2/contacts/analytics' do
        with_options scope: [:data, :attributes] do
          response_field 'first_gift_not_received_count', 'First Gift Not Received Count', 'Type' => 'Number'
          response_field 'partners_30_days_late_count',   'Partners 30 Days Late Count',   'Type' => 'Number'
          response_field 'partners_60_days_late_count',   'Partners 60 Days Late Count',   'Type' => 'Number'
        end

        example 'Analytics [GET]', document: :contacts do
          explanation "Viewing Analytical information for the User's Contacts for all Account Lists"
          do_request

          check_resource(additional_attribute_keys)
          expect(resource_object.keys).to match_array expected_attribute_keys
          expect(response_status).to eq 200
          expect(birthday_relationship_data.count).to eq(2)
          expect(anniversary_relationship_data.count).to eq(1)
        end
      end
    end

    context 'when specifying an `account_list_id`' do
      # show
      get '/api/v2/contacts/analytics' do
        parameter 'filter[account_list_id]', 'An Account List ID to scope the analytics to'

        with_options scope: [:data, :attributes] do
          response_field 'first_gift_not_received_count', 'First Gift Not Received Count', 'Type' => 'Number'
          response_field 'partners_30_days_late_count',   'Partners 30 Days Late Count',   'Type' => 'Number'
          response_field 'partners_60_days_late_count',   'Partners 60 Days Late Count',   'Type' => 'Number'
        end

        example 'Analytics [GET]', document: :contacts do
          explanation "Viewing Analytical information for a specific Account List's Contacts"
          do_request filter: { account_list_id: alternate_account_list.uuid }

          check_resource(additional_attribute_keys)
          expect(resource_object.keys).to match_array expected_attribute_keys
          expect(response_status).to eq 200
          expect(birthday_relationship_data.count).to eq(1)
          expect(anniversary_relationship_data.count).to eq(0)
        end
      end
    end
  end
end
