require 'spec_helper'

describe SetupController do
  before(:each) do
    @user = FactoryGirl.create(:user)
    sign_in(:user, @user)
  end

  describe 'show' do
    it 'should get the org_accounts step' do
      get :show, id: :org_accounts
      expect(response).to be_success
    end

    it 'should redirect to the org_accounts step if the user does not have an org account' do
      get :show, id: :finish
      expect(response).to redirect_to('/setup/org_accounts')
    end

    it 'should mark setup_mode false when finished' do
      FactoryGirl.create(:organization_account, person: @user)
      @user.update_attributes(preferences: { setup: true })
      get :show, id: :finish
      expect(response).to redirect_to('/')
      expect(@user.reload.setup_mode?).to eq(false)
    end

    context 'settings step' do
      let!(:org_account) { FactoryGirl.create(:organization_account, person: @user) }

      before do
        org_account.organization.update(country: 'Brazil', default_currency_code: 'AFN')
        get :show, id: :settings
      end

      it 'sets up @account_list_organizations' do
        account_list_organizations = assigns(:account_list_organizations)
        expect(account_list_organizations.first[1]).to_not be_empty
      end

      it 'sets up preferences_prefills' do
        preferences_prefills = assigns(:preferences_prefills)
        org_preferences = preferences_prefills[org_account.organization.name]
        expect(org_preferences).to_not be_empty
      end
    end
  end
end
