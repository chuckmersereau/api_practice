require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'User Accounts' do
  context 'authorized user' do
    let(:user)            { create(:user_with_full_account) }
    let(:account_list)    { user.account_lists.first }
    let(:account_list_id) { account_list.uuid }
    let(:access_token)    { JsonWebToken.encode(user_uuid: user.uuid) }

    get '/auth/user/google' do
      header 'Host', 'auth.mpdx.org'
      parameter :access_token, 'the user JWT'
      parameter :redirect_to, 'the URI to redirect the user to when auth is complete'

      example 'Authorize with Google' do
        do_request
        expect(response_status).to eq 302
      end
    end

    get '/auth/user/prayer_letters' do
      header 'Host', 'auth.mpdx.org'
      parameter :account_list_id, 'the ID of the account_list to add the Prayer Letters account to'
      parameter :access_token, 'the user JWT'
      parameter :redirect_to, 'the URI to redirect the user to when auth is complete'

      example 'Authorize with Prayer Letters' do
        do_request
        expect(response_status).to eq 302
      end
    end
  end
end
