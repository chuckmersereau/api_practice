require 'spec_helper'

describe Admin::HomeController do
  context '#index' do
    it 'works for admin users' do
      login(create(:admin_user))
      get :index
      expect(response).to be_success
    end

    it 'does not work for non-admin users' do
      login(create(:user))
      get :index
      expect(response).to_not be_success
    end
  end
end
