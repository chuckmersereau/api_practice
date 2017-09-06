require 'rails_helper'

describe AccountListInviteMailer do
  context '#email' do
    let(:user_inviting) { create(:user) }

    context 'coach' do
      let!(:invite) { create(:account_list_invite, invited_by_user_id: user_inviting.id, invite_user_as: 'coach') }
      let!(:mail) { AccountListInviteMailer.email(invite) }

      it 'renders the headers and the body contains the correct link' do
        expect(mail.subject).to eq('You\'ve been invited to be a coach for an account on MPDX')
        expect(mail.to).to eq(['joe@example.com'])
        expect(mail.from).to eq(['support@mpdx.org'])
        expect(mail.body.raw_source).to include("https://mpdx.org/account_lists/#{invite.account_list.uuid}/accept_invite/#{invite.uuid}?code=#{invite.code}")
        expect(mail.body.raw_source).to include('You are getting this email because an MPDX user has invited you to be a coach for an account they manage.')
      end
    end

    context 'user' do
      let!(:invite) { create(:account_list_invite, invited_by_user_id: user_inviting.id, invite_user_as: 'user') }
      let!(:mail) { AccountListInviteMailer.email(invite) }

      it 'renders the headers and the body contains the correct link' do
        expect(mail.subject).to eq('You\'ve been invited to access an account on MPDX')
        expect(mail.to).to eq(['joe@example.com'])
        expect(mail.from).to eq(['support@mpdx.org'])
        expect(mail.body.raw_source).to include("https://mpdx.org/account_lists/#{invite.account_list.uuid}/accept_invite/#{invite.uuid}?code=#{invite.code}")
        expect(mail.body.raw_source).to include('You are getting this email because an MPDX user has invited you to access an account they manage.')
      end
    end
  end
end
