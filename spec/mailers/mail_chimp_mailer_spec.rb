require 'rails_helper'

describe MailChimpMailer do
  let(:user) { create(:user_with_account, email: 'test@user.com') }
  let(:account_list) { user.account_lists.first }

  describe '#invalid_email_addresses' do
    let(:email) { 'bill@facebook.com' }
    let(:contact1) { create(:contact_with_person, account_list: account_list) }
    let(:contact2) { create(:contact_with_person, account_list: account_list) }
    let(:emails_with_person_ids) { { email => [contact1.primary_person.id, contact2.primary_person.id] } }
    subject { described_class.invalid_email_addresses(account_list, user, emails_with_person_ids) }

    before do
      contact1.primary_person.update(email: email)
      contact2.primary_person.update(email: email)
    end

    it 'renders the mail' do
      expect(subject.to).to eq([user.email_address])
      expect(subject.body.raw_source).to include("https://mpdx.org/contacts/#{contact1.id}")
      expect(subject.body.raw_source).to include("https://mpdx.org/contacts/#{contact2.id}")
    end
  end
end
