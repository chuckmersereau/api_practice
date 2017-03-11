require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Merges' do
  include_context :json_headers
  # This is the scope in how these endpoints will be organized in the
  # generated documentation.
  #
  # :entities should be used for "top level" resources, and the top level
  # resources should be used for nested resources.
  #
  # Ex: Api > v2 > Contacts                   - :entities would be the scope
  # Ex: Api > v2 > Contacts > Email Addresses - :contacts would be the scope
  documentation_scope = :contacts_api_merges

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'contacts' }
  let(:request_type)  { 'merges' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user) { create(:user_with_account) }

  let(:account_list) { user.account_lists.first }

  let!(:winner) { create(:contact, name: 'Doe, John', account_list: account_list) }
  let!(:loser) { create(:contact, name: 'Doe, John 2', account_list: account_list) }

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  let(:form_data) { build_data(attributes, relationships: relationships) }

  # List your expected resource keys vertically here (alphabetical please!)
  let(:resource_attributes) do
    %w(
      avatar
      church_name
      created_at
      deceased
      donor_accounts
      envelope_greeting
      greeting
      last_activity
      last_appointment
      last_donation
      last_letter
      last_phone_call
      last_pre_call
      last_thank
      likely_to_give
      locale
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
      status_valid
      suggested_changes
      tag_list
      timezone
      total_donations
      uncompleted_tasks_count
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      account_list
      addresses
      appeals
      contacts_referred_by_me
      contacts_that_referred_me
      donor_accounts
      last_six_donations
      people
      primary_person
      tasks
    )
  end
  # List out any additional attribute keys that will be alongside
  # the attributes of the resources.
  #
  # Remove if not needed.
  let(:additional_attribute_keys) do
    %w(
      relationships
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # create
    post '/api/v2/contacts/merges' do
      with_options scope: [:data, :attributes] do
        parameter 'winner_id', 'The ID of the contact that should win the merge'
        parameter 'loser_id', 'The ID of the contact that should lose the merge'
      end

      let(:relationships) do
        {
          loser: {
            data: {
              type: 'contacts',
              id: loser.uuid
            }
          },
          winner: {
            data: {
              type: 'contacts',
              id: winner.uuid
            }
          }
        }
      end

      let(:attributes) { {} }

      example 'Merge [CREATE]', document: documentation_scope do
        explanation 'Create Merge'
        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end
  end
end
