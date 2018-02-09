require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Analytics' do
  include_context :json_headers
  doc_helper = DocumentationHelper.new(resource: [:contacts, :analytics])

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
      partners_90_days_late_count
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
        doc_helper.insert_documentation_for(action: :show, context: self)

        example doc_helper.title_for(:show), document: doc_helper.document_scope do
          explanation doc_helper.description_for(:show)
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
        doc_helper.insert_documentation_for(action: :show, context: self)

        example doc_helper.title_for(:show), document: doc_helper.document_scope do
          explanation doc_helper.description_for(:show)
          do_request filter: { account_list_id: alternate_account_list.id }

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
