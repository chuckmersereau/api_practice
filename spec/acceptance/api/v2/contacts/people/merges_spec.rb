require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Merges' do
  include_context :json_headers

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'people' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let!(:contact) { create(:contact, name: 'Doe, John', account_list: account_list) }
  let(:contact_id) { contact.uuid }
  let!(:winner) { create(:person, first_name: 'John', last_name: 'Doe') }
  let!(:loser) { create(:person, first_name: 'John', last_name: 'Doe 2') }

  before do
    contact.people << winner
    contact.people << loser
  end

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  let(:form_data) { build_data(attributes) }

  # List your expected resource keys vertically here (alphabetical please!)
  let(:resource_attributes) do
    %w(
      anniversary_day
      anniversary_month
      anniversary_year
      avatar
      birthday_day
      birthday_month
      birthday_year
      created_at
      deceased
      first_name
      gender
      last_name
      marital_status
      middle_name
      suffix
      title
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      email_addresses
      facebook_accounts
      family_relationships
      linkedin_accounts
      master_person
      phone_numbers
      twitter_accounts
      websites)
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

  # This is the scope in how these endpoints will be organized in the
  # generated documentation.
  #
  # :entities should be used for "top level" resources, and the top level
  # resources should be used for nested resources.
  #
  # Ex: Api > v2 > Contacts                   - :entities would be the scope
  # Ex: Api > v2 > Contacts > Email Addresses - :contacts would be the scope
  document = :people

  context 'authorized user' do
    before { api_login(user) }

    # create
    post '/api/v2/contacts/:contact_id/people/merges' do
      with_options scope: [:data, :attributes] do
        parameter 'winner_id', 'The ID of the person that should win the merge'
        parameter 'loser_id', 'The ID of the person that should lose the merge'
      end

      let(:attributes) { { winner_id: winner.uuid, loser_id: loser.uuid } }

      example 'Merge [CREATE]', document: document do
        explanation 'Create Merge'
        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end
  end
end
