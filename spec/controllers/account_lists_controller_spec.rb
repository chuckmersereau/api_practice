require 'spec_helper'

describe AccountListsController do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  before do
    sign_in(:user, user)
    allow(subject).to receive(:current_user) { user }
    allow(subject).to receive(:current_account_list) { account_list }
  end

  context '#sharing' do
    it "assigns mergeable_accounts to be the user's non current account lists" do
      expect(user.account_lists.count).to eq(2)
      get :sharing
      expect(assigns(:mergeable_accounts)).to eq([user.account_lists.second])
    end
  end

  context '#share' do
    it 'sends the account invite with the specified email if it is valid' do
      expect(AccountListInvite).to receive(:send_invite)
        .with(user, account_list, 'john@example.com')
      post :share, email: 'john@example.com'
    end

    it 'does not send an invite for an invalid email' do
      expect(user).to_not receive(:send_account_list_invite)
      post :share, email: 'invalid_email_address'
    end
  end

  context '#accept_invite' do
    let(:invited_account) { create(:account_list) }
    let!(:invite) do
      create(:account_list_invite, code: 'code', account_list: invited_account)
    end

    it 'redirect with a flash alert for an invalid invite code' do
      expect do
        get :accept_invite, code: 'bad_code', id: invited_account.id
      end.to_not change(user.account_lists, :count)
      expect(flash[:alert]).to be_present
    end

    it 'redirect with a flash alert for an invalid account id' do
      expect do
        get :accept_invite, code: 'code', id: (invited_account.id + 1)
      end.to_not change(user.account_lists, :count)
      expect(flash[:alert]).to be_present
    end

    it 'accepts the invite if the code and id are valid' do
      get :accept_invite, code: 'code', id: invited_account.id
      expect(user.account_lists.reload).to include(invited_account)
    end

    it 'does not allow an invite to be used if it was accepted by another user' do
      user2 = create(:user)
      invite.accept(user2)

      get :accept_invite, code: 'code', id: invited_account.id
      expect(flash[:alert]).to be_present
      expect(user.account_lists.reload).to_not include(invited_account)
    end

    it 'give a flash notice (but no alert) if the user re-accepts an invite' do
      invite.accept(user)
      get :accept_invite, code: 'code', id: invited_account.id
      expect(flash[:notice]).to be_present
      expect(flash[:alert]).to_not be_present
    end

    after { expect(subject).to redirect_to(root_path) }
  end

  context '#merge' do
    it 'does not merge if merge_id is for an account_list the user does not own' do
      not_owned_account = create(:account_list)
      expect_any_instance_of(AccountList).to_not receive(:merge)
      post :merge, merge_id: not_owned_account.id
    end

    it 'merges account lists if the merge_id account list is owned by the user' do
      owned_account = user.account_lists.second
      expect(account_list).to receive(:merge).with(owned_account)
      post :merge, merge_id: owned_account.id
    end

    it 'does not let the current account list merge with itself' do
      expect_any_instance_of(AccountList).to_not receive(:merge)
      post :merge, merge_id: account_list.id
    end
  end
end
