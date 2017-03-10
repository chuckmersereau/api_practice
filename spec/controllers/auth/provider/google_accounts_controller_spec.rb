require 'rails_helper'

describe Auth::Provider::GoogleAccountsController, :auth, type: :controller do
  routes { Auth::Engine.routes }
  let(:user) { create(:user_with_account) }

  before(:each) do
    auth_login(user)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:google]
  end

  it 'should find or create a Google Account' do
    expect(Person::GoogleAccount)
      .to receive(:find_or_create_from_auth)
      .with(OmniAuth.config.mock_auth[:google], user)
    get :create
  end
end
