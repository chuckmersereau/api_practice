require 'rails_helper'

describe AccountListInviteMailer do
  context '#email' do
    let(:user_inviting) { create(:user) }
    let(:invite) { create(:account_list_invite, invited_by_user_id: user_inviting.id) }
    let(:mail) { AccountListInviteMailer.email(invite) }

    it 'renders the headers and the body contains the correct link' do
      expect(mail.subject).to eq('Account access invite')
      expect(mail.to).to eq(['joe@example.com'])
      expect(mail.from).to eq(['support@mpdx.org'])
      expect(mail.body.raw_source).to include("https://mpdx.org/account_lists/#{invite.account_list.uuid}/accept_invite/#{invite.uuid}?code=#{invite.code}")
    end
  end
end
