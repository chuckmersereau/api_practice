require 'spec_helper'

describe AccountMailer do
  context '#google_account_refresh' do
    it 'assigns the to correctly' do
      email = build(:email_address)
      person = double(email: email)
      integration = build_stubbed(:google_integration)

      mail = AccountMailer.google_account_refresh(person, integration)

      expect(mail.to).to eq [email.email]
    end
  end
end
