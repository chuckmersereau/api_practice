require 'spec_helper'

describe NotificationType::ThankPartnerOncePerYear do
  let!(:thank_partner_once_per_year) { NotificationType::ThankPartnerOncePerYear.first_or_initialize }

  context '#check' do
    it 'does not add a notification for a partner with frequency of semi-annual or rarer' do
      account_list = create(:account_list)
      contact = create(:contact, account_list: account_list, pledge_frequency: 6.0)
      create(:task, activity_type: 'Thank', contacts: [contact], account_list: contact.account_list,
                    start_at: 2.years.ago)
      notifications = thank_partner_once_per_year.check(contact.account_list)
      expect(notifications.length).to eq(0)
    end
  end
end
