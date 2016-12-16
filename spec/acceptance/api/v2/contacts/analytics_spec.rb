require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Analytics' do
  include_context :json_headers

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'contact_analytics' }

  # Remove this and the authorized context below if not authorizing your requests.
  let!(:user)         { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:contact_with_anniversary_with_week) do
    person = create(:person, anniversary_month: Date.current.month,
                             anniversary_day: Date.current.day)

    contact = create(:contact, account_list_id: account_list.id,
                               status: 'Partner - Financial')

    contact.people << person
    contact
  end

  let!(:contact_with_birthday_this_week) do
    person = create(:person, birthday_month: Date.current.month,
                             birthday_day: Date.current.day)

    contact = create(:contact, account_list_id: account_list.id,
                               status: 'Partner - Financial')

    contact.people << person
    contact
  end

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  let(:form_data) { build_data(attributes) }

  let(:expected_attribute_keys) do
    # list your expected resource keys vertically here (alphabetical please!)
    %w(
      first_gift_not_received_count
      partners_30_days_late_count
      partners_60_days_late_count
    )
  end

  let(:additional_attribute_keys) do
    %w(
      relationships
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # show
    get '/api/v2/contacts/analytics' do
      with_options scope: [:data, :attributes] do
        response_field 'first_gift_not_received_count', 'First Gift Not Received Count', 'Type' => 'Number'
        response_field 'partners_30_days_late_count',   'Partners 30 Days Late Count',   'Type' => 'Number'
        response_field 'partners_60_days_late_count',   'Partners 60 Days Late Count',   'Type' => 'Number'
      end

      example 'Contact Analytics [GET]', document: :contacts do
        explanation "Viewing Analytical information for this Account List's Contacts"
        do_request

        check_resource(additional_attribute_keys)
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
  end
end
