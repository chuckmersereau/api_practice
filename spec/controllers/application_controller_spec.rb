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
end
