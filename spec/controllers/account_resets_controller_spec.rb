require 'spec_helper'

describe AccountResetsController do
  context '#create' do
    it 'triggers reset for current account, gives notice, redirects to root' do
      user = create(:user_with_account)
      account_list = user.account_lists.first
      login(user)
      reset = instance_double(AccountList::Reset, reset_shallow_and_queue_deep: nil)
      allow(AccountList::Reset).to receive(:new).with(account_list, user) { reset }

      post :create

      expect(AccountList::Reset).to have_received(:new).with(account_list, user)
      expect(reset).to have_received(:reset_shallow_and_queue_deep)
      expect(flash[:notice]).to be_present
      expect(response).to redirect_to(root_path)
    end

    it 'deletes the account list once sidekiq is run' do
      login(create(:user_with_account))

      expect do
        Sidekiq::Testing.inline! do
          post :create
        end
      end.to change(AccountList, :count).by(-1)
    end
  end
end
