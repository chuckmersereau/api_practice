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
      expect(assigns(:preference_set).user).to eq(user)
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
  end
end
