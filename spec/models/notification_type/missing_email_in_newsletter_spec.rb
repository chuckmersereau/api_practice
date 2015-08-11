require 'spec_helper'

describe NotificationType::MissingEmailInNewsletter do
  subject { NotificationType::MissingEmailInNewsletter.first_or_initialize }
  let(:account_list) { create(:account_list) }
  let(:person_with_email) do
    person = build(:person)
    person.email_address = { email: 'john@example.com' }
    person.save
    person
  end

  context '#missing_info_filter' do
    it 'excludes contacts not on the email newsletter' do
      account_list.contacts << create(:contact, send_newsletter: nil)
      account_list.contacts << create(:contact, send_newsletter: 'Physical')
      expect_filtered_contacts([])
    end

    it 'excludes enewsletter contacts with a person with a valid email address' do
      contact = create(:contact, send_newsletter: 'Email')
      contact.people << person_with_email
      account_list.contacts << contact
      expect_filtered_contacts([])
    end

    it 'excludes contacts with a person w/ email address, one person wo/ one' do
      contact = create(:contact, send_newsletter: 'Email')
      contact.people << person_with_email
      contact.people << create(:person)
      account_list.contacts << contact
      expect_filtered_contacts([])
    end

    it 'includes enewsletter contacts with no people' do
      contact = create(:contact, send_newsletter: 'Both')
      account_list.contacts << contact
      expect_filtered_contacts([contact])
    end

    it 'includes enewsletter contacts with a person with no email address' do
      contact = create(:contact, send_newsletter: 'Both')
      contact.people << create(:person)
      account_list.contacts << contact
      expect_filtered_contacts([contact])
    end

    it 'includes contacts on the newsletter with a historic email address' do
      contact = create(:contact, send_newsletter: 'Email')
      contact.people << person_with_email
      person_with_email.email_addresses.first.update(historic: true)
      account_list.contacts << contact
      expect_filtered_contacts([contact])
    end
  end

  def expect_filtered_contacts(expected)
    actual = subject.missing_info_filter(account_list.contacts).to_a
    expect(actual.size).to eq(expected.size)
    expected.each { |c| expect(actual).to include(c) }
  end
end
