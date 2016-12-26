require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Referrers' do
  header 'Content-Type', 'application/vnd.api+json'
  let(:resource_type) { 'contacts' }
  let(:user) { create(:user_with_account) }
  let(:contact)    { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.uuid }
  let!(:resource) { create(:contact).tap { |referrer| contact.referrals_to_me << referrer } }

  let(:expected_attribute_keys) do
    %w(
      account_list_id
      avatar
      church_name
      created_at
      deceased
      donor_accounts
      last_activity
      last_appointment
      last_letter
      last_phone_call
      last_pre_call
      last_thank
      likely_to_give
      magazine
      name
      next_ask
      no_appeals
      notes
      notes_saved_at
      pledge_amount
      pledge_currency
      pledge_currency_symbol
      pledge_frequency
      pledge_received
      pledge_start_date
      send_newsletter
      square_avatar
      status
      tag_list
      timezone
      uncompleted_tasks_count
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      referrals_to_me
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/contacts/:contact_id/referrers' do
      example_request 'list referrers' do
        explanation 'List of Contacts that have referred the given Contact'
        check_collection_resource(1, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end
  end
end
