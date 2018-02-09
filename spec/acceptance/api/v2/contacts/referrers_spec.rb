require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Referrers' do
  include_context :json_headers
  documentation_scope = :contacts_api_referrers

  let(:resource_type) { 'contacts' }
  let(:user)          { create(:user_with_account) }
  let(:contact)       { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id)    { contact.id }

  let!(:resource) do
    create(:contact).tap do |referrer|
      contact.contacts_that_referred_me << referrer
    end
  end

  let(:resource_attributes) do
    %w(
      avatar
      church_name
      created_at
      deceased
      direct_deposit
      envelope_greeting
      greeting
      last_activity
      last_appointment
      last_donation
      last_letter
      last_phone_call
      last_pre_call
      last_thank
      late_at
      likely_to_give
      locale
      magazine
      name
      next_ask
      no_appeals
      no_gift_aid
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
      status_valid
      suggested_changes
      tag_list
      timezone
      uncompleted_tasks_count
      updated_at
      updated_in_db_at
      website
    )
  end

  let(:resource_associations) do
    %w(
      contacts_that_referred_me
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/contacts/:contact_id/referrers' do
      example 'list referrers', document: documentation_scope do
        explanation 'List of Contacts that have referred the given Contact'
        do_request

        check_collection_resource(1, ['relationships'])
        expect(response_status).to eq 200
      end
    end
  end
end
