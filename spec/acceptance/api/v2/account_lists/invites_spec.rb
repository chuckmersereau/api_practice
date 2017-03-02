require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Invites' do
  include_context :json_headers
  documentation_scope = :account_lists_api_invites

  let(:resource_type) { 'account_list_invites' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  let!(:invite)         { create(:account_list_invite, account_list: account_list) }
  let(:id)              { invite.uuid }

  let(:expected_attribute_keys) do
    %w(
      accepted_at
      code
      created_at
      recipient_email
      updated_at
      updated_in_db_at
    )
  end

  let(:resource_associations) do
    %w(
      accepted_by_user
      cancelled_by_user
      invited_by_user
    )
  end

  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/account_lists/:account_list_id/invites' do
      parameter 'account_list_id', 'Account List ID', required: true
      response_field 'data',       'Data', type: 'Array[Object]'

      example 'Invite [LIST]', document: documentation_scope do
        explanation 'List of Invites associated with the Account List'
        do_request

        check_collection_resource(1, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/invites/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'accepted_at',          'Accepted At',          type: 'String'
        response_field 'accepted_by_user_id',  'Accepted by User ID',  type: 'Number'
        response_field 'account_list_id',      'Account List ID',      type: 'Number'
        response_field 'cancelled_by_user_id', 'Cancelled by user ID', type: 'Number'
        response_field 'code',                 'Code',                 type: 'String'
        response_field 'created_at',           'Created At',           type: 'String'
        response_field 'invited_by_user_id',   'Invited by User ID',   type: 'Number'
        response_field 'recipient_email',      'Recipient Email',      type: 'String'
        response_field 'updated_at',           'Updated At',           type: 'String'
        response_field 'updated_in_db_at',     'Updated In Db At',     type: 'String'
      end

      example 'Invite [GET]', document: documentation_scope do
        explanation 'The Account List Invite with the given ID'
        do_request
        check_resource(['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(resource_object['code']).to eq invite.code
        expect(response_status).to eq 200
      end
    end

    post '/api/v2/account_lists/:account_list_id/invites' do
      let(:new_account_list_invite) { attributes_for :account_list_invite }
      let(:email)                   { new_account_list_invite[:recipient_email] }
      let('recipient_email')        { email }
      let(:form_data)               { build_data(recipient_email: recipient_email) }

      parameter 'recipient_email', 'Recipient Email', scope: [:data, :attributes], required: true

      example 'Invite [CREATE]', document: documentation_scope do
        explanation 'List of Invites associated with the Account List'
        do_request data: form_data

        expect(response_status).to eq 201
        expect(resource_object['recipient_email']).to eq email
      end
    end

    delete '/api/v2/account_lists/:account_list_id/invites/:id' do
      example 'Invite [DELETE]', document: documentation_scope do
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
