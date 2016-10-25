require 'spec_helper'

describe Admin::ResetController do
  context '#create' do
    let!(:user) { create(:user_with_account) }

    it 'resets the user after the email is given as a param' do
      login(create(:admin_user))

      expect do
        post :create, params: { resetted_user_email: user.relay_accounts.first.email, reason: 'having fun testing' }
      end.to change(AccountListUser, :count).by(-1)
    end
  end
end
