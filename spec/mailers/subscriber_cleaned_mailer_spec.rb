require 'rails_helper'

describe SubscriberCleanedMailer do
  let!(:account_list) { create(:account_list) }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:person) { create(:person) }
  let!(:person_email) { create(:email_address) }
  let!(:user) { create(:user) }
  let!(:user_email) { create(:email_address) }

  before do
    contact.people << person
    user.email_addresses << user_email
    person.email_addresses << person_email
    account_list.users << user
  end

  it 'renders the mail' do
    mail = SubscriberCleanedMailer.subscriber_cleaned(account_list, person_email)
    expect(mail.subject).to eq('MailChimp subscriber email bounced')
    expect(mail.to).to eq([user_email.email])
    expect(mail.from).to eq(['support@mpdx.org'])
    expect(mail.body.raw_source).to include("https://mpdx.org/contacts/#{contact.id}?personId=#{person.id}")
  end
end
