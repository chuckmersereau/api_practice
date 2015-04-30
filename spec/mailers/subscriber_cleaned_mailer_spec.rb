require 'spec_helper'

describe SubscriberCleanedMailer do
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:person) { create(:person) }
  let(:email) { create(:email_address) }

  before do
    contact.people << person
    person.email_addresses << email
    account_list.users << create(:user)
  end

  it 'pulls in the newsletter list, and users name and emails from account list' do
    expect do
      SubscriberCleanedMailer.subscriber_cleaned(account_list, email)
    end.to_not raise_error
  end
end
