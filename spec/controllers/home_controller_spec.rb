require 'spec_helper'

describe HomeController do
  render_views

  describe 'when not logged in' do
    before { logout_test_user }

    describe "GET 'index'" do
      it 'redirects to splash page' do
        get 'index'
        expect(response).to redirect_to('/login')
      end

      it 'should use relay on us domain' do
        request.host = 'us'
        get 'index'
        expect(response).to redirect_to('/auth/relay')
      end

      it 'should use key on secure domain' do
        request.host = 'mpdxs'
        get 'index'
        expect(response).to redirect_to('/auth/key')
      end
    end
    describe 'login' do
      it 'returns http success' do
        get 'login'
        expect(response).to be_success
      end
    end
  end

  describe 'when logged in' do
    before(:each) do
      @user = FactoryGirl.create(:user_with_account)
      sign_in(:user, @user)
    end

    describe "GET 'index'" do
      it 'returns http success' do
        get 'index'
        expect(response).to be_success
      end

      it 'should redirect to setup if user is still in setup mode' do
        @user.update_attributes(preferences: { setup: true })
        get 'index'
        expect(response).to redirect_to('/setup/org_accounts')
      end

      it 'should include graph' do
        @user.account_lists.first.update_attributes(monthly_goal: '100')
        get 'index'
        expect(response).to render_template('home/_donations_summary_chart')
      end
    end

    describe '#check_welcome_stages' do
      it 'removes completed steps' do
        al = @user.account_lists.first
        @user.update_attribute(:setup, [:import, :goal, :contacts])
        al.update_attribute(:monthly_goal, 100)
        4.times { |i| al.contacts << create(:contact, name: i) }
        2.times { create(:tnt_import, user: @user) }
        get 'index'
        expect(@user.reload.setup).to_not include :goal
        expect(@user.reload.setup).to_not include :contacts
        expect(@user.reload.setup).to_not include :import
      end
    end
  end

  describe '#privacy' do
    it 'succeeds' do
      get 'privacy'
      expect(response).to be_success
    end
  end
end
