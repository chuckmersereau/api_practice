require 'spec_helper'

describe NotificationType::LongTimeFrameGift do
  let!(:long_time_frame_gift) { NotificationType::LongTimeFrameGift.first_or_initialize }
  let!(:da) { create(:designation_account) }
  let!(:account_list) { create(:account_list) }
  let!(:contact) { create(:contact, account_list: account_list, pledge_amount: 9.99, pledge_frequency: 12) }
  let!(:donor_account) { create(:donor_account) }
  let!(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }
  let!(:old_donation) do
    create(:donation, donor_account: donor_account, designation_account: da, donation_date: Date.today << 12)
  end

  before do
    account_list.account_list_entries.create!(designation_account: da)
    contact.donor_accounts << donor_account
    contact.update_donation_totals(old_donation)
    contact.update_donation_totals(donation)
  end

  context '#check' do
    it 'adds a notification if a gift comes in for a long time frame partner' do
      expect(long_time_frame_gift.check(account_list).size).to eq(1)
    end

    it 'does not add a notification if it was the first gift' do
      old_donation.destroy!
      expect(long_time_frame_gift.check(account_list)).to be_empty
    end

    it 'does not add a notfication if donation was not equal to the pledge' do
      donation.update(amount: 5)
      expect(long_time_frame_gift.check(account_list)).to be_empty
    end
  end

  context '#task_description' do
    it 'adds the gift frequency in correctly' do
      donation.update(donation_date: Date.new(2015, 3, 18))
      notification = contact.notifications.new(donation: donation)
      description = 'Doe, John gave their Annual gift of MyString9.99 on March 18, 2015. Send them a Thank You.'
      expect(long_time_frame_gift.task_description(notification)).to eq(description)
    end
  end
end
