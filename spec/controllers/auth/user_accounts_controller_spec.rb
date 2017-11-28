require 'rails_helper'

describe Auth::UserAccountsController, :auth, type: :controller do
  routes { Auth::Engine.routes }
  let(:user) { create(:user_with_account) }
  let(:provider) { :google }

  context 'with a logged in user' do
    before(:each) do
    end

    it 'should redirect the user to the requested provider' do
      auth_login(user)
      get :create, provider: provider
      expect(response.status).to be(302)
      expect(response.location).to include(provider.to_s)
    end

    it 'should add the current user to the session' do
      auth_login(user)
      get :create, provider: provider
      expect(session['warden.user.user.key']).to be(user.id)
    end

    it 'should store an account_list_id param in the session' do
      auth_login(user)
      get :create, provider: provider, account_list_id: '4'
      expect(session['account_list_id']).to eq('4')
    end

    context 'provider is donorhub' do
      let(:provider) { :donorhub }
      let!(:organization) do
        create(
          :organization,
          oauth_url: 'https://www.mytntware.com/dataserver/toontown/staffportal/oauth/authorize.aspx'
        )
      end
      it 'should redirect the user to the requested provider' do
        auth_login(user)
        get :create, provider: provider, organization_id: organization.uuid
        expect(response.status).to be(302)
        expect(response.location).to include("#{provider}?oauth_url=#{URI.encode(organization.oauth_url)}")
      end

      context 'organization does not exist' do
        it 'should return an unauthorized response' do
          get :create, provider: provider, organization_id: '123'
          expect(response.status).to be(401)
        end
      end
    end

    context 'provider is sidekiq' do
      let(:provider) { :sidekiq }
      let(:user) { create(:user_with_account, developer: true) }
      it 'should redirect user to sidekiq' do
        auth_login(user)
        get :create, provider: provider
        expect(response.status).to be(302)
        expect(response.location).to include('sidekiq')
      end

      context 'user is not developer' do
        let(:user) { create(:user_with_account, developer: false) }
        it 'should return an unauthorized response' do
          get :create, provider: provider
          expect(response.status).to be(401)
        end
      end
    end
  end

  context 'with no logged in user' do
    it 'should return an unauthorized response' do
      get :create, provider: provider
      expect(response.status).to be(401)
    end
  end
end
