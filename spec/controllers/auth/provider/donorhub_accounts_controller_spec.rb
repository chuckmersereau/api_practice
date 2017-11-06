require 'rails_helper'

describe Auth::Provider::DonorhubAccountsController, :auth, type: :controller do
  routes { Auth::Engine.routes }
  let(:user) { create(:user_with_account) }
  let(:oauth_url) { 'https://www.mytntware.com/dataserver/toontown/staffportal/oauth/authorize.aspx' }

  before(:each) do
    auth_login(user)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:donorhub]
  end

  it 'should find or create a Organization Account' do
    expect(Person::OrganizationAccount)
      .to receive(:find_or_create_from_auth)
      .with(OmniAuth.config.mock_auth[:donorhub][:credentials][:token], oauth_url, user)
    get :create, oauth_url: oauth_url
  end
end
