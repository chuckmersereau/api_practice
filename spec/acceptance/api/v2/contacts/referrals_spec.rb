require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Contact Referrals' do
  include_context :json_headers

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'contact_referrals' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:contact)     { create(:contact, account_list: account_list) }
  let(:contact_id)  { contact.uuid }

  let(:referral)    { create(:contact, account_list: account_list) }
  let(:referral_id) { referral.uuid }

  let(:contact_referral) do
    create(:contact_referral, referred_by: contact, referred_to: referral)
  end

  let(:id) { contact_referral.uuid }

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  let(:form_data) { build_data(attributes) }

  let(:resource_attributes) do
    # list your expected resource keys vertically here (alphabetical please!)
    %w(
      created_at
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

    # index
    get '/api/v2/contacts/:contact_id/referrals' do
      before { contact_referral }

      example_request 'list referrals' do
        check_collection_resource(1, additional_attribute_keys)

        creation_time = Time.zone.parse(resource_object['created_at'])

        expect(creation_time.to_s).to eq contact_referral.created_at.to_s
        expect(response_status).to eq 200
      end
    end

    # show
    get '/api/v2/contacts/:contact_id/referrals/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'created_at', 'Created At', 'Type' => 'String'
        response_field 'updated_at', 'Updated At', 'Type' => 'String'
      end

      example_request 'show referral' do
        check_resource(additional_attribute_keys)

        creation_time = Time.zone.parse(resource_object['created_at'])

        expect(creation_time.to_s).to eq contact_referral.created_at.to_s
        expect(response_status).to eq 200
      end
    end

    # create
    post '/api/v2/contacts/:contact_id/referrals/' do
      with_options scope: [:data, :attributes] do
        parameter 'referred_by_id', 'ID of the Contact making the Referral', 'Type' => 'Number'
        parameter 'referred_to_id', 'ID of the Contact being Referred',      'Type' => 'Number'
      end

      let(:attributes) do
        {
          referred_by_id: contact.uuid,
          referred_to_id: referral.uuid
        }
      end

      example 'create referral' do
        do_request data: form_data
        check_resource(additional_attribute_keys)

        expect(response_status).to eq 201

        contact_referrals_by_me_uuids = contact.contact_referrals_by_me.map(&:uuid)
        created_id = json_response['data']['id']
        expect(contact_referrals_by_me_uuids).to include created_id
      end
    end

    # update
    put '/api/v2/contacts/:contact_id/referrals/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'referred_by_id', 'ID of the Contact making the Referral', 'Type' => 'Number'
        parameter 'referred_to_id', 'ID of the Contact being Referred',      'Type' => 'Number'
      end

      let(:alternate) { create(:contact, account_list: account_list) }

      let(:attributes) do
        {
          referred_to_id: alternate.uuid,
          updated_in_db_at: referral.updated_at
        }
      end

      example 'update referral' do
        expect(contact_referral.referred_to_id).to eq referral.id

        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200

        expect(contact_referral.reload.referred_to_id).to eq alternate.id
      end
    end

    # update
    patch '/api/v2/contacts/:contact_id/referrals/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'referred_by_id', 'ID of the Contact making the Referral', 'Type' => 'Number'
        parameter 'referred_to_id', 'ID of the Contact being Referred',      'Type' => 'Number'
      end

      let(:alternate) { create(:contact, account_list: account_list) }

      let(:attributes) do
        {
          referred_to_id: alternate.uuid,
          updated_in_db_at: referral.updated_at
        }
      end

      example 'update referral' do
        expect(contact_referral.referred_to_id).to eq referral.id

        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200

        expect(contact_referral.reload.referred_to_id).to eq alternate.id
      end
    end

    # # destroy
    delete '/api/v2/contacts/:contact_id/referrals/:id' do
      example_request 'delete referral' do
        expect(response_status).to eq 204
      end
    end
  end
end
