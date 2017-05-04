require 'rails_helper'

describe Auth::UserAccountsController, :auth, type: :controller do
  routes { Auth::Engine.routes }
  let(:user) { create(:user_with_account) }
  let(:provider) { :google }

  context 'with a logged in user' do
    before(:each) do
    end

    it 'redirects the user to the requested provider' do
      auth_login(user)
      get :create, provider: provider
      expect(response.status).to be(302)
      expect(response.location).to match(/#{provider}/)
    end

    it 'adds the current user to the session' do
      auth_login(user)
      get :create, provider: provider
      expect(session['warden.user.user.key']).to be(user.id)
    end

    it 'stores an account_list_id param in the session' do
      auth_login(user)
      get :create, provider: provider, account_list_id: '4'
      expect(session['account_list_id']).to eq('4')
    end
  end

  context 'with no logged in user' do
    it 'should return an unauthorized response' do
      get :create, provider: provider
      expect(response.status).to be(401)
    end
  end
end
