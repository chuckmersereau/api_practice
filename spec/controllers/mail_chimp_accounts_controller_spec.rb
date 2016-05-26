require 'spec_helper'

describe MailChimpAccountsController do
  let(:valid_attributes) { { api_key: 'foo-us4', primary_list_id: 'asdf' } }

  before(:each) do
    @user = create(:user_with_account)
    sign_in(:user, @user)
    @account_list = @user.account_lists.first
    allow(controller).to receive(:current_account_list).and_return(@account_list)
    @contact = create(:contact, account_list: @account_list)

    stub_request(:get, 'https://apikey:foo-us4@us4.api.mailchimp.com/3.0/lists')
      .to_return(body: { lists: [] }.to_json)
  end

  context 'index' do
    let(:chimp) { create(:mail_chimp_account, account_list: @account_list) }

    before do
      allow(@account_list).to receive(:mail_chimp_account).and_return(chimp)
    end

    it 'should validate the current key if there is a mail chimp account' do
      expect(chimp).to receive(:validate_key).and_return(false)
      allow(chimp).to receive(:primary_list)

      get :index
    end

    it "should redirect to the 'new' page if the current account is not active" do
      allow(chimp).to receive(:validate_key)

      expect(chimp).to receive(:active?).and_return(false)

      get :index

      expect(response).to redirect_to(new_mail_chimp_account_path)
    end

    it "should redirect to the 'edit' page if there is no primary list" do
      allow(chimp).to receive(:validate_key)
      allow(chimp).to receive(:active)

      expect(chimp).to receive(:primary_list).and_return(false)

      get :index

      expect(response).to redirect_to(edit_mail_chimp_account_path(chimp))
    end
  end

  context '#create' do
    it 'creates a new mailchimp account' do
      expect do
        post :create, mail_chimp_account: valid_attributes
      end.to change(MailChimpAccount, :count).by(1)
    end
  end

  context '#update' do
    it 'updates an existing mail chimp account' do
      mc_account = create(:mail_chimp_account, account_list: @account_list)
      put :update, id: mc_account.id,
                   mail_chimp_account: valid_attributes.merge(auto_log_campaigns: true)
      expect(mc_account.reload.auto_log_campaigns).to be true
    end
  end

  context '#new' do
    it 'initializes a mail chimp account to auto log campaigns by default' do
      expect($rollout).to receive(:active?) { true }
      get :new
      expect(assigns(:mail_chimp_account).auto_log_campaigns).to be true
    end
  end
end
