require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Pledges' do
  include_context :json_headers

  # This is required!
  # This is the resource's JSONAPI.org `type` attribute to be validated against.
  let(:resource_type) { 'pledges' }

  # Remove this and the authorized context below if not authorizing your requests.
  let(:user) { create(:user_with_account) }

  let(:attributes) { attributes_for(:pledge).except(:account_list_id, :contact_id, :donation_id) }

  let(:account_list) { create(:account_list, users: [user]) }
  let(:contact) { create(:contact, account_list: account_list) }
  let!(:pledge) { create(:pledge, account_list: account_list, contact: contact) }

  let(:id) { pledge.uuid }
  let(:account_list_id) { account_list.uuid }

  # This is the reference data used to create/update a resource.
  # specify the `attributes` specifically in your request actions below.
  let(:form_data) do
    build_data(attributes).merge(
      relationships: {
        contact: {
          data: {
            id: contact.uuid,
            type: 'contacts'
          }
        }
      }
    )
  end

  # List your expected resource keys vertically here (alphabetical please!)
  let(:expected_attribute_keys) do
    %w(
      amount
      created_at
      expected_date
      received_not_processed
      updated_at
      updated_in_db_at
    )
  end

  let(:expected_relationships) do
    %w(
      account_list
      contact
      donation
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

  # DOCUMENTATION SCOPE
  #
  # This is the scope in how these endpoints will be organized in the
  # generated documentation.
  #
  # :entities should be used for "top level" route resources, like AccountList, Contacts, Tasks, etc
  # For nested resources, a symbolized version of a "top level" resource should be used.
  #
  # Ex: Api > v2 > Contacts                   - :entities would be the scope
  # Ex: Api > v2 > Contacts > Email Addresses - :contacts would be the scope
  # Ex: Api > v2 > Contacts > People > Phones - :contacts would be the scope
  #
  # As such, replace FIXME below for the desired scope for the endpoints below,
  # and feel free to remove this sentence.

  documentation_scope = :pledges

  context 'authorized user' do
    before { api_login(user) }

    # index
    get '/api/v2/account_lists/:account_list_id/pledges' do
      parameter 'account_list_id', 'Account List ID', required: true

      with_options scope: :filter do
        parameter 'contact_id', 'Filter by Contact Id', type: 'String'
      end

      with_options scope: :sort do
        parameter 'amount',                 'Sort by Amount',                                                       type: 'Number'
        parameter 'expected_date',          'Sort by Expected Date',                                                type: 'String'
        parameter 'received_not_processed', 'Value is set to true if the donation was received, but not processed', type: 'Boolean'
      end

      example 'Pledge [LIST]', document: documentation_scope do
        explanation 'List of Pledges'
        do_request

        check_collection_resource(1, additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # show
    get '/api/v2/account_lists/:account_list_id/pledges/:id' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'Pledge ID',       required: true

      with_options scope: :data do
        with_options scope: :attributes do
          # list out the attributes here
          response_field 'amount',                 'Amount of Pledge',                                                     type: 'Number'
          response_field 'expected_date',          'Expected Date of Donation',                                            type: 'String'
          response_field 'received_not_processed', 'Value is set to true if the donation was received, but not processed', type: 'Boolean'
        end

        with_options scope: :relationships do
          response_field 'donation', 'Donation associated to Pledge',  type: 'Object'
          response_field 'contact',  'Contact associated to Pledge',   type: 'Object'
        end
      end

      example 'Pledge [GET]', document: documentation_scope do
        explanation 'The Pledge for the given ID'
        do_request

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # create
    post '/api/v2/account_lists/:account_list_id/pledges' do
      parameter 'account_list_id', 'Account List ID', required: true

      with_options scope: :data do
        with_options scope: :attributes do
          # list out the POST params here
          parameter 'amount',        'Amount of expected donation', type: 'Number'
          parameter 'expected_date', 'Expected Date of Donation',   type: 'String'
        end

        with_options scope: :relationships do
          parameter 'donation', 'Donation associated to Pledge', type: 'Object'
          parameter 'contact',  'Contact associated to Pledge',  type: 'Object'
        end
      end

      example 'Pledge [CREATE]', document: documentation_scope do
        explanation 'Create Pledge'
        do_request data: form_data

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 201
      end
    end

    # update
    put '/api/v2/account_lists/:account_list_id/pledges/:id' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'Pledge ID',       required: true

      with_options scope: [:data, :attributes] do
        # list out the PUT params here
        parameter 'amount',        'Amount of expected donation', type: 'Number'
        parameter 'expected_date', 'Expected Date of Donation',   type: 'String'
      end

      example 'Pledge [UPDATE]', document: documentation_scope do
        explanation 'Update Pledge'

        # Merge with the updated_in_db_at value provided by the server.
        # Ex: updated_in_db_at: email_address.updated_at
        do_request data: form_data.merge!(attributes: { updated_in_db_at: pledge.updated_at })

        check_resource(additional_attribute_keys)
        expect(response_status).to eq 200
      end
    end

    # destroy
    delete '/api/v2/account_lists/:account_list_id/pledges/:id' do
      parameter 'account_list_id', 'Account List ID', required: true
      parameter 'id',              'Pledge ID',       required: true

      example 'Pledge [DELETE]', document: documentation_scope do
        explanation 'Delete Pledge'
        do_request

        expect(response_status).to eq 204
      end
    end
  end
end
