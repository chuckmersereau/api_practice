require 'spec_helper'

describe Admin::OfflineOrgController do
  context '#create' do
    let(:resetted_user) { create(:user) }
    it 'creates a new offline org and redirects to admin home' do
      login(create(:admin_user))
      expect do
        post :create, resetted_user_email: resetted_user.email, reason: 'having fun testing'
      end.to change(resetted_user.reload)
    end
  end
end
