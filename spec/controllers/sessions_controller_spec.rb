require 'spec_helper'

describe SessionsController do
  before do
    # This is necessary for the devise route mappings to work, see this link:
    # https://github.com/plataformatec/devise#test-helpers
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  context '#destroy' do
    it 'signs out non-impersonated user and redirects to login page' do
      user = create(:user)
      sign_in(:user, user)
      expect(subject.current_user).to eq user
      get :destroy
      expect(subject.current_user).to be nil
      expect(response).to redirect_to login_path
    end

    it 'signs out impersonated user and redirects impersonator to admin page' do
      impersonated = create(:user)
      impersonator = create(:user)
      session[:impersonator_id] = impersonator.id
      sign_in(:user, impersonated)
      get :destroy
      expect(subject.current_user).to eq impersonator
      expect(response).to redirect_to admin_home_index_path
    end
  end
end
