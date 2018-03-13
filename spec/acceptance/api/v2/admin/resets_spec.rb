require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Resets' do
  include_context :json_headers

  let(:admin_user) { create(:user, admin: true) }
  let(:reset_user) { create(:user_with_account) }
  let!(:key_account) { create(:key_account, person: reset_user) }
  let(:account_list) { reset_user.account_lists.order(:created_at).first }
  let(:request_type) { 'resets' }
  let(:form_data) do
    build_data(resetted_user_email: key_account.email,
               reason: 'Resetting User Account',
               account_list_name: account_list.name)
  end

  context 'authorized user' do
    before { api_login(admin_user) }

    post '/api/v2/admin/resets' do
      with_options scope: [:data, :attributes] do
        parameter :resetted_user_email, 'The Key/Relay Email of the user with access to the account to be reset'
        parameter :reason,              'The reason for resetting this account'
        parameter :account_list_name,   'The exact name of the account list to reset'
      end

      example 'Reset [CREATE]', document: false do
        explanation 'This endpoint allows an admin to reset an account.'

        do_request data: form_data

        expect(response_status).to eq 200
        expect(json_response['data']['attributes']['name']).to eq account_list.name
      end
    end
  end
end
