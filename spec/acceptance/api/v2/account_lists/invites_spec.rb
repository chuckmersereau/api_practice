require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Account Lists > Invites' do
  include_context :json_headers
  documentation_scope = :account_lists_api_invites

  let(:resource_type) { 'account_list_invites' }
  let!(:user)         { create(:user_with_account) }

  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }

  let!(:invite)         { create(:account_list_invite, account_list: account_list, accepted_by_user: nil, cancelled_by_user: nil) }
  let!(:invite_coach)   { create(:account_list_invite, account_list: account_list, accepted_by_user: nil, cancelled_by_user: nil, invite_user_as: 'coach') }
  let(:id)              { invite.id }

  let(:expected_attribute_keys) do
    %w(
      accepted_at
      code
      created_at
      invite_user_as
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

        check_collection_resource(2, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end

      example 'Invite [LIST] Filter User Invites', document: false do
        explanation 'List of User Invites associated with the Account List'
        do_request(filter: { invite_user_as: 'user' })
        check_collection_resource(1, ['relationships'])
        expect(resource_object['invite_user_as']).to eq 'user'
        expect(response_status).to eq 200
      end

      example 'Invite [LIST] Filter Coach Invites', document: false do
        explanation 'List of Coach Invites associated with the Account List'
        do_request(filter: { invite_user_as: 'coach' })
        check_collection_resource(1, ['relationships'])
        expect(resource_object['invite_user_as']).to eq 'coach'
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
      let!(:new_account_list_invite) { attributes_for :account_list_invite }
      let!(:recipient_email)         { new_account_list_invite[:recipient_email] }
      let!(:invite_user_as)          { 'user' }
      let!(:form_data)               { build_data(recipient_email: recipient_email, invite_user_as: invite_user_as) }

      parameter 'recipient_email', 'Recipient Email', scope: [:data, :attributes], required: true
      parameter 'invite_user_as', 'Kind of invite ("user" or "coach")', scope: [:data, :attributes], required: true

      example 'Invite [CREATE]', document: documentation_scope do
        explanation 'Creates the invite associated to the given account_list'
        do_request data: form_data

        expect(response_status).to eq 201
        expect(resource_object['recipient_email']).to eq recipient_email
        expect(resource_object['invite_user_as']).to eq 'user'
      end
    end

    put '/api/v2/account_lists/:account_list_id/invites/:id/accept' do
      let(:form_data) { build_data(code: invite.code) }

      parameter 'code', 'Acceptance code', scope: [:data, :attributes], required: true

      example 'Invite [ACCEPT]', document: documentation_scope do
        explanation 'Accepts the invite'
        do_request data: form_data

        expect(response_status).to eq 200
        expect(resource_object['accepted_at']).to be_present
      end
    end

    delete '/api/v2/account_lists/:account_list_id/invites/:id' do
      example 'Invite [CANCEL]', document: documentation_scope do
        explanation 'Cancels the invite'
        do_request
        expect(response_status).to eq 204
      end
    end
  end
end
