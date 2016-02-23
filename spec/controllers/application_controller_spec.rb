require 'spec_helper'

describe ApplicationController do
  describe 'After log out' do
    it 'redirects to login' do
      expect(controller.send(:after_sign_out_path_for, @user)).to eq(login_url)
    end
    it 'redirects to relay' do
      @request.session[:signed_in_with] = 'relay'
      expect(controller.send(:after_sign_out_path_for, @user)).to eq("https://signin.relaysso.org/cas/logout?service=#{login_url}")
    end
    it 'redirects to key' do
      @request.session[:signed_in_with] = 'key'
      expect(controller.send(:after_sign_out_path_for, @user)).to eq("https://thekey.me/cas/logout?service=#{login_url}")
    end
  end

  describe 'paper trail whodunnit', type: :controller, versioning: true do
    controller(ApplicationController) do
      def destroy
        AccountList.find(params[:id]).destroy
        render nothing: true
      end
    end

    it 'sets whodunnit based on signed in user for normal user' do
      user = create(:user_with_account)
      sign_in(user)
      expect do
        delete :destroy, id: user.account_lists.first.id
      end.to change(Version, :count).by_at_least(1)
      expect(Version.last.whodunnit).to eq user.id.to_s
    end

    it 'sets whodunnit based on impersonator for impersonated user' do
      user = create(:user_with_account)
      sign_in(user)
      impersonator = create(:user)
      session[:impersonator_id] = impersonator.id
      expect do
        delete :destroy, id: user.account_lists.first.id
      end.to change(Version, :count).by_at_least(1)
      expect(Version.last.whodunnit).to eq impersonator.id.to_s
    end
  end
end
