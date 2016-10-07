require 'spec_helper'

describe Admin::ResetController do
  context '#create' do
    let(:account_list) { create(:account_list)}
    let(:resetted_user) { create(:user, account_lists: [account_list]) }

    it 'resets the user after the email is given as a param' do
      login(create(:admin_user))
      expect do
        post :create, resetted_user_email: resetted_user.email, reason: 'having fun testing'
      end.to change { account_list.reload.account_list_users.count }
    end
  end
end
