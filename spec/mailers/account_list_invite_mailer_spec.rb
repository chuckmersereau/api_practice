require 'spec_helper'

describe AccountListInviteMailer do
  context '#email' do
    let(:invite) { build(:account_list_invite) }
    let(:mail) { AccountListInviteMailer.email(invite) }

    it 'renders the headers' do
      expect(mail.subject).to eq('Account access invite')
      expect(mail.to).to eq(['joe@example.com'])
      expect(mail.from).to eq(['support@mpdx.org'])
    end
  end
end
