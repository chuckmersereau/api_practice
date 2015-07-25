require 'spec_helper'

describe Api::V1::MailChimpAccountsController do
    before(:each) do
      @user = create(:user_with_account)
      sign_in(:user, @user)
      @account_list = @user.account_lists.first
      allow(controller).to receive(:current_account_list).and_return(@account_list)
      @contact = create(:contact, account_list: @account_list)

      stub_request(:post, "https://us4.api.mailchimp.com/1.3/?method=lists").
          with(:body => "%7B%22apikey%22%3A%22fake-us4%22%7D",
               :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "", :headers => {})
    end

    context 'index' do
      let(:chimp) { create(:mail_chimp_account, account_list: @account_list) }

      before do
        allow(@account_list).to receive(:mail_chimp_account).and_return(chimp)
      end

      it 'should return lists available for appeals' do
        get :index
        expect(response).to be_success
        json = JSON.parse(response.body)
        expect(json).to include 'id'
        expect(json).to include 'name'
      end
    end

end
