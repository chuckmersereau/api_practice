require 'spec_helper'

describe NotificationType::MissingAddressInNewsletter do
  subject { NotificationType::MissingAddressInNewsletter.first_or_initialize }
  let(:account_list) { create(:account_list) }

  context '#missing_info_filter' do
    it 'excludes contacts not on the physical newsletter' do
      account_list.contacts << create(:contact, send_newsletter: nil)
      account_list.contacts << create(:contact, send_newsletter: 'Email')
      expect_filtered_contacts([])
    end

    it 'excludes contacts on the newsletter with a valid address' do
      contact = create(:contact, send_newsletter: 'Physical')
      contact.addresses << create(:address, historic: nil)
      account_list.contacts << contact
      expect_filtered_contacts([])
    end

    it 'includes contacts on the newsletter without an address' do
      contact = create(:contact, send_newsletter: 'Both')
      account_list.contacts << contact
      expect(contact.addresses.count).to eq(0)
      expect_filtered_contacts([contact])
    end

    it 'includes contacts on the newsletter with a historic/deleted address' do
      contact1 = create(:contact, send_newsletter: 'Physical')
      contact1.addresses << create(:address, historic: true)
      account_list.contacts << contact1

      contact2 = create(:contact, send_newsletter: 'Both')
      contact2.addresses << create(:address, deleted: true)
      account_list.contacts << contact2

      expect_filtered_contacts([contact1, contact2])
    end
  end

  def expect_filtered_contacts(expected)
    actual = subject.missing_info_filter(account_list.contacts).to_a
    expect(actual.size).to eq(expected.size)
    expected.each { |c| expect(actual).to include(c) }
  end
end
