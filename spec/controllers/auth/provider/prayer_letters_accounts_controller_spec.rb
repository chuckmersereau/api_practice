require 'rails_helper'

describe Auth::Provider::PrayerLettersAccountsController, :auth, type: :controller do
  routes { Auth::Engine.routes }
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }

  before(:each) do
    auth_login(user)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:prayer_letters]
  end

  context 'with no preexisting PrayerLettersAccount' do
    it 'should create a PrayerLettersAccount' do
      expect do
        get :create, nil, account_list_id: account_list_id
      end.to change(PrayerLettersAccount, :count).by(1)
    end
  end

  context 'with a preexisting PrayerLettersAccount' do
    let!(:prayer_letters_account) { create(:prayer_letters_account, account_list: account_list) }

    it 'should not create a PrayerLettersAccount' do
      expect do
        get :create, nil, account_list_id: account_list_id
      end.to_not change(PrayerLettersAccount, :count)
    end

    it 'should update the existing PrayerLettersAccount' do
      expect do
        get :create, nil, account_list_id: account_list_id
        prayer_letters_account.reload
      end.to change { prayer_letters_account.oauth2_token }
    end
  end
end
