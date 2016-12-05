require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts People Email Addresses' do
  header 'Content-Type', 'application/vnd.api+json'
  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'email_addresses' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user)          { create(:user_with_account) }
  let(:account_list)  { user.account_lists.first }

  let(:contact)       { create(:contact, account_list: account_list) }
  let(:contact_id)    { contact.id }

  let(:person)        { create(:person, contacts: [contact]) }
  let(:person_id)     { person.id }

  let!(:email_address) { create(:email_address, person: person) }
  let(:id)             { email_address.id }

  let(:form_data) { build_data(attributes) }

  let(:expected_attribute_keys) do
    # list your expected resource keys vertically here (alphabetical please!)
    %w(
      created_at
      email
      historic
      location
      primary
      updated_at
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/contacts/:contact_id/people/:person_id/email_addresses' do
      example_request 'list email addresses' do
        explanation 'List of Email Addresses belonging to the Person'

        check_collection_resource(1, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq email_address.email
        expect(response_status).to eq 200
      end
    end

    # show
    get '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at', 'Created At', 'Type' => 'String'
        response_field 'email',      'Email',      'Type' => 'String'
        response_field 'historic',   'Historic',   'Type' => 'Boolean'
        response_field 'location',   'Location',   'Type' => 'String'
        response_field 'primary',    'Primary',    'Type' => 'Boolean'
        response_field 'updated_at', 'Updated At', 'Type' => 'String'
      end

      example_request 'show email address' do
        check_resource(['relationships'])
        expect(resource_object.keys.sort).to eq expected_attribute_keys
        expect(resource_object['email']).to  eq email_address.email
        expect(response_status).to eq 200
      end
    end

    # create
    post '/api/v2/contacts/:contact_id/people/:person_id/email_addresses' do
      with_options scope: [:data, :attributes] do
        parameter 'email',    'Email for the Email Address'
        parameter 'primary',  "Whether or not the email should be the Person's primary email"
        parameter 'location', 'The location of the Email Address, such as "home", "mobile", "office"'
        parameter 'historic', 'Set to true when an Email Address should no longer be used'
      end

      let(:attributes) { attributes_for(:email_address) }

      example 'create email address' do
        do_request data: form_data

        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq attributes[:email]
        expect(response_status).to eq 200
      end
    end

    # update
    put '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'email',    'Email for the Email Address'
        parameter 'primary',  "Whether or not the email should be the Person's primary email"
        parameter 'location', 'The location of the Email Address, such as "home", "mobile", "office"'
        parameter 'historic', 'Set to true when an Email Address should no longer be used'
      end

      let(:attributes) { email_address.attributes }

      before { attributes.merge!(email: 'new-email@example.com') }

      example 'update email address' do
        do_request data: form_data

        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq 'new-email@example.com'
        expect(response_status).to eq 200
      end
    end

    # update
    patch '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'email',    'Email for the Email Address'
        parameter 'primary',  "Whether or not the email should be the Person's primary email"
        parameter 'location', 'The location of the Email Address, such as "home", "mobile", "office"'
        parameter 'historic', 'Set to true when an Email Address should no longer be used'
      end

      let(:attributes) { email_address.attributes }

      before { attributes.merge!(email: 'new-email@example.com') }

      example 'update email address' do
        do_request data: form_data

        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['email']).to eq 'new-email@example.com'
        expect(response_status).to eq 200
      end
    end

    # destroy
    delete '/api/v2/contacts/:contact_id/people/:person_id/email_addresses/:id' do
      example_request 'delete email address' do
        expect(response_status).to eq 200
      end
    end
  end
end
