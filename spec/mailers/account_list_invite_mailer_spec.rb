require 'spec_helper'

describe AccountListInviteMailer do
  context '#email' do
    let(:user_inviting) { create(:user) }
    let(:invite) { build(:account_list_invite, invited_by_user_id: user_inviting.id) }
    let(:mail) { AccountListInviteMailer.email(invite) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Account access invite')
      expect(mail.to).to eq(['joe@example.com'])
      expect(mail.from).to eq(['support@mpdx.org'])
    end
  end
end
