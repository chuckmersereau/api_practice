require 'rails_helper'

describe AccountMailer do
  describe '#mailchimp_required_merge_field' do
    it 'renders the mail' do
      email = build(:email_address)
      account_list = double(users: [double(email: email)])
      mail = AccountMailer.mailchimp_required_merge_field(account_list)
      expect(mail.subject).to eq('Mailchimp List is requiring an additional merge field')
      expect(mail.to).to eq([email.email])
      expect(mail.from).to eq(['support@mpdx.org'])
      expect(mail.body.raw_source).to include('https://mpdx.org/preferences/integrations?selectedTab=mailchimp')
    end
  end

  describe '#google_account_refresh' do
    it 'renders the mail' do
      email = build(:email_address)
      person = double(email: email)
      integration = build_stubbed(:google_integration)
      mail = AccountMailer.google_account_refresh(person, integration)
      expect(mail.subject).to eq('Google account needs to be refreshed')
      expect(mail.to).to eq([email.email])
      expect(mail.from).to eq(['support@mpdx.org'])
      expect(mail.body.raw_source).to include('https://mpdx.org/preferences/integrations?selectedTab=google')
    end
  end
end
