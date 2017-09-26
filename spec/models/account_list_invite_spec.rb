require 'rails_helper'

describe AccountListInvite do
  let(:invite) { create(:account_list_invite, accepted_by_user: nil) }
  let(:user) { create(:user) }
  let(:account_list) { create(:account_list) }

  context '#accept' do
    it 'returns false and does nothing if a second user tries to accept' do
      invite.accept(user)

      user2 = create(:user)
      expect do
        expect(invite.accept(user2)).to be_falsey
      end.to_not change(AccountListUser, :count)
    end

    it 'returns false and does nothing if the invite was canceled' do
      invite.cancel(user)
      user2 = create(:user)
      expect do
        expect(invite.accept(user2)).to be_falsey
      end.to_not change(AccountListUser, :count)
    end

    context 'user' do
      it 'creates an account list entry for recipient and updates the accepting info' do
        expect(invite.accept(user)).to be_truthy
        expect(user.account_lists.to_a).to eq([invite.account_list])
        invite.reload
        expect(invite.accepted_by_user).to eq(user)
        expect(invite.accepted_at).to be_present
      end

      it 'does not create a second account list entry if the user already has access' do
        user.account_lists << invite.account_list
        expect do
          invite.accept(user)
        end.to_not change(AccountListUser, :count)
      end

      it 'returns true if same user accepts again, but does not create new entry' do
        invite.accept(user)
        expect do
          expect(invite.accept(user)).to be_truthy
        end.to_not change(AccountListUser, :count)
      end
    end

    context 'coach' do
      let(:coach) { user.becomes(User::Coach) }

      before do
        invite.update(invite_user_as: 'coach')
      end

      it 'creates an account list entry for recipient and updates the accepting info' do
        expect(invite.accept(user)).to be_truthy
        expect(coach.coaching_account_lists.to_a).to eq([invite.account_list])
        invite.reload
        expect(invite.accepted_by_user).to eq(user)
        expect(invite.accepted_at).to be_present
      end

      it 'does not create a second account list entry if the user already has access' do
        coach.coaching_account_lists << invite.account_list
        expect do
          invite.accept(user)
        end.to_not change(AccountListCoach, :count)
      end

      it 'returns true if same user accepts again, but does not create new entry' do
        invite.accept(user)
        expect do
          expect(invite.accept(user)).to be_truthy
        end.to_not change(AccountListCoach, :count)
      end
    end
  end

  context '.send_invite' do
    context 'user' do
      it 'creates an invite with a random code and sends the invite email' do
        expect(SecureRandom).to receive(:hex).with(32) { 'code' }
        expect_delayed_email(AccountListInviteMailer, :email)
        invite = AccountListInvite.send_invite(user, account_list, 'test@example.com', 'user')
        expect(invite.invited_by_user).to eq(user)
        expect(invite.invite_user_as).to eq('user')
        expect(invite.code).to eq('code')
        expect(invite.recipient_email).to eq('test@example.com')
        expect(invite.account_list).to eq(account_list)
      end
    end
    context 'coach' do
      it 'creates an invite with a random code and sends the invite email' do
        expect(SecureRandom).to receive(:hex).with(32) { 'code' }
        expect_delayed_email(AccountListInviteMailer, :email)
        invite = AccountListInvite.send_invite(user, account_list, 'test@example.com', 'coach')
        expect(invite.invited_by_user).to eq(user)
        expect(invite.invite_user_as).to eq('coach')
        expect(invite.code).to eq('code')
        expect(invite.recipient_email).to eq('test@example.com')
        expect(invite.account_list).to eq(account_list)
      end
    end
  end

  context '#cancel' do
    it 'sets the canceling user and is then considered cancelled', versioning: true do
      expect(invite.cancelled?).to be false
      user2 = create(:user)
      invite.cancel(user2)
      expect(invite.cancelled?).to be true
      expect(invite.cancelled_by_user).to eq user2
    end
  end
end
