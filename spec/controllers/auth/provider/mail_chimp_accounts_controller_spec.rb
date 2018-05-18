require 'rails_helper'

describe Auth::Provider::MailChimpAccountsController, :auth, type: :controller do
  routes { Auth::Engine.routes }
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:account_list_id) { account_list.id }

  before(:each) do
    auth_login(user)
    request.env['omniauth.auth'] = OmniAuth.config.mock_auth[:mailchimp]
  end

  context 'with no preexisting MailChimpAccount' do
    it 'should create a MailChimpAccount' do
      expect do
        get :create, nil, account_list_id: account_list_id
      end.to change(MailChimpAccount, :count).by(1)
      expect(MailChimpAccount.order(:created_at).last.active).to be true
    end
  end

  context 'with a preexisting MailChimpAccount' do
    let!(:mail_chimp_account) { create(:mail_chimp_account, account_list: account_list) }

    it 'should not create a MailChimpAccount' do
      expect do
        get :create, nil, account_list_id: account_list_id
      end.to_not change(MailChimpAccount, :count)
    end

    it 'should update the existing MailChimpAccount' do
      expect do
        get :create, nil, account_list_id: account_list_id
        mail_chimp_account.reload
      end.to change { mail_chimp_account.api_key }.and(change { mail_chimp_account.active }.to(true))
    end
  end
end
