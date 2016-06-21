require 'spec_helper'

describe Api::V1::UsersController do
  describe 'api' do
    before do
      @user = create(:user_with_account)
      sign_in(:user, @user)
    end

    let(:user) { create(:user_with_account) }
    let!(:contact) { create(:contact, account_list: user.account_lists.first, pledge_amount: 100) }

    context '#show' do
      it 'gets preferences' do
        get :show, id: 'me'
        expect(response).to be_success
      end
    end

    context '#put' do
      it 'updates preferences' do
        AccountList.any_instance.stub(:id).and_return(1)

        put :update, id: 'me', 'user' => { 'preferences' => { 'contacts_filter' => { '1' => { 'limit' => 1000, 'timezone' => 'EST' } } } }
        expect(response).to be_success
        expect(session[:prefs][:contacts][:limit]).to eq('1000')
      end
    end
  end
end
