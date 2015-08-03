require 'spec_helper'

describe AccountListInvite do
  let(:invite) { create(:account_list_invite) }
  let(:recipient_user) { create(:user) }

  context '#accept_and_destroy' do
    it 'creates an account list entry for recipient user and destroys the invite' do
      invite.accept_and_destroy(recipient_user)
      expect(recipient_user.account_lists.to_a).to eq([invite.account_list])
    end

    it 'does not create a second account list entry if the user already has access' do
      recipient_user.account_lists << invite.account_list

      expect do
        invite.accept_and_destroy(recipient_user)
      end.to_not change(AccountListUser, :count)
    end
  end
end
