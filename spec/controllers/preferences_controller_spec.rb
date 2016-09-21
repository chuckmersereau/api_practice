require 'spec_helper'

describe PreferencesController do
  let(:user) { create(:user_with_account) }

  before(:each) do
    sign_in(:user, user)
  end

  context '#index' do
    it 'gets the index' do
      get :index
      expect(response).to be_success
    end
  end

  context '#update' do
    it 'updates successfully' do
      preferences = {
        first_name: 'John', email: 'john@example.com', account_list_name: 'New'
      }
      put :update, id: 1, preference_set: preferences
      expect(response).to redirect_to(preferences_path)
      expect(user.account_lists.first.reload.name).to eq 'New'
    end

    it 'renders errors when update fails' do
      put :update, id: 1, preference_set: {}
      expect(response).to be_success
      expect(flash.alert).to include("Email can't be blank")
    end

    it 'should not redirect to setup if user is still in setup mode' do
      user.update_attributes(preferences: { setup: true })
      preferences = { email: 'john@example.com', account_list_name: 'New' }
      put :update, id: 1, preference_set: preferences, redirect: '/setup/settings'
      expect(user.account_lists.first.reload.name).to eq 'New'
      expect(response).to redirect_to('/setup/settings')
    end
  end
end
