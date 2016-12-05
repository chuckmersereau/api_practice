require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Invites' do
  let(:resource_type) { 'account_list_invites' }

  let!(:user)           { create(:user_with_account) }
  let!(:account_list)   { user.account_lists.first }
  let(:account_list_id) { account_list.id }
  let!(:invite)         { create(:account_list_invite, account_list: account_list) }
  let(:id)              { invite.id }

  let(:expected_attribute_keys) do
    %w(
      accepted_at
      code
      created_at
      recipient_email
      updated_at
    )
  end

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/account_lists/:account_list_id/invites' do
      parameter 'account_list_id', 'Account List ID', required: true
      response_field 'data',       'Data', 'Type' => 'Array[Object]'

      example_request 'list invites of account list' do
        explanation 'Invites of selected account list'

        check_collection_resource(1, ['relationships'])
        expect(resource_object.keys).to match_array expected_attribute_keys
        expect(response_status).to eq 200
      end
    end

    get '/api/v2/account_lists/:account_list_id/invites/:id' do
      with_options scope: [:data, :attributes] do
        response_field 'accepted_at',          'Accepted At',          'Type' => 'String'
        response_field 'accepted_by_user_id',  'Accepted by User ID',  'Type' => 'Number'
        response_field 'account_list_id',      'Account List ID',      'Type' => 'Number'
        response_field 'cancelled_by_user_id', 'Cancelled by user ID', 'Type' => 'Number'
        response_field 'code',                 'Code',                 'Type' => 'String'
        response_field 'invited_by_user_id',   'Invited by User ID',   'Type' => 'Number'
        response_field 'recipient_email',      'Recipient Email',      'Type' => 'String'
      end

      example_request 'get invite' do
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

      parameter 'recipient_email', 'Recipient Email', scope: [:data, :attributes], required: true

      example_request 'create invite' do
        expect(resource_object['recipient_email']).to eq email
        expect(response_status).to eq 200
      end
    end

    delete '/api/v2/account_lists/:account_list_id/invites/:id' do
      example_request 'delete invite' do
        expect(response_status).to eq 200
      end
    end
  end
end
