require 'rails_helper'

describe AccountListResetMailer do
  context '#email' do
    let(:email) { create(:email_address) }
    let(:user) { create(:user, email: email) }
    let(:reset_log) { create(:admin_reset_log) }

    context 'invite' do
      let!(:mail) { AccountListResetMailer.logout(user, reset_log) }

      it 'renders the headers and the body contains the correct link' do
        expect(mail.subject).to eq('You must log in to MPDX again')
        expect(mail.to).to eq([email.email])
        expect(mail.from).to eq(['support@mpdx.org'])
        expect(mail.body.raw_source).to include(
          'You are getting this email because an MPDX administrator has reset your Account.'
        )
      end
    end
  end
end
