require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Referrals' do
  include_context :json_headers
  documentation_scope = :contacts_api_referrals

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'contact_referrals' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:contact)     { create(:contact, account_list: account_list) }
  let(:contact_id)  { contact.id }

  let(:referral)    { create(:contact, account_list: account_list) }
  let(:referral_id) { referral.id }

  let(:contact_referral) do
    create(:contact_referral, referred_by: contact, referred_to: referral)
  end

  let(:id) { contact_referral.id }

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  let(:form_data) { build_data(attributes, relationships: relationships) }

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
        response_field 'created_at', 'Created At', type: 'String'
        response_field 'updated_at', 'Updated At', type: 'String'
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
        parameter 'referred_by_id', 'ID of the Contact making the Referral', type: 'Number'
        parameter 'referred_to_id', 'ID of the Contact being Referred',      type: 'Number'
      end

      let(:attributes) do
        {}
      end

      let(:relationships) do
        {
          referred_to: {
            data: {
              type: 'contacts',
              id: referral.id
            }
          },
          referred_by: {
            data: {
              type: 'contacts',
              id: contact.id
            }
          }
        }
      end

      example 'create referral', document: documentation_scope do
        do_request data: form_data
        check_resource(additional_attribute_keys)

        expect(response_status).to eq 201

        contact_referrals_by_me_ids = contact.contact_referrals_by_me.map(&:id)
        created_id = json_response['data']['id']
        expect(contact_referrals_by_me_ids).to include created_id
      end
    end

    # update
    put '/api/v2/contacts/:contact_id/referrals/:id' do
      with_options scope: [:data, :attributes] do
        parameter 'referred_by_id', 'ID of the Contact making the Referral', type: 'Number'
        parameter 'referred_to_id', 'ID of the Contact being Referred',      type: 'Number'
      end

      let(:alternate) { create(:contact, account_list: account_list) }

      let(:attributes) do
        { updated_in_db_at: contact_referral.updated_at }
      end

      let(:relationships) do
        {
          referred_to: {
            data: {
              type: 'contacts',
              id: alternate.id
            }
          },
          referred_by: {
            data: {
              type: 'contacts',
              id: contact.id
            }
          }
        }
      end

      example 'update referral', document: documentation_scope do
        expect(contact_referral.referred_to_id).to eq referral.id

        do_request data: form_data
        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200

        expect(contact_referral.reload.referred_to_id).to eq alternate.id
      end
    end

    # destroy
    delete '/api/v2/contacts/:contact_id/referrals/:id' do
      example 'delete referral', document: documentation_scope do
        explanation 'Delete a Referral'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
