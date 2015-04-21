require 'spec_helper'

describe NotificationType::LargerGift do
  let!(:larger_gift) { NotificationType::LargerGift.first_or_initialize }
  let!(:da) { create(:designation_account) }
  let!(:account_list) { create(:account_list) }
  let!(:contact) { create(:contact, account_list: account_list, pledge_amount: 5) }
  let!(:donor_account) { create(:donor_account) }
  let!(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }

  before do
    account_list.account_list_entries.create!(designation_account: da)
    contact.donor_accounts << donor_account
    contact.update_donation_totals(donation)
  end

  context '#check' do
    it 'adds a notification if a gift comes from a financial partner and is more than the pledge' do
      expect(larger_gift.check(account_list).size).to eq(1)
    end

    it 'adds a notification if a gift came last month from a financial partner and is more than the pledge' do
      donation.update(donation_date: Date.today << 1)
      contact.update(last_donation_date: nil)
      contact.update_donation_totals(donation)
      expect(larger_gift.check(account_list).size).to eq(1)
    end

    it "doesn't add a notification if gift came before start of last month" do
      donation.update(donation_date: Date.today << 2)
      expect(larger_gift.check(account_list)).to be_empty
    end

    it 'adds a notification if two gifts which total to more than the pledge came in' do
      donation.update(amount: 5, donation_date: Date.today.beginning_of_month)
      expect(larger_gift.check(account_list)).to be_empty

      donation2 = create(:donation, donor_account: donor_account,
                                    designation_account: da, donation_date: Date.today.end_of_month)
      expect(larger_gift.check(account_list).size).to eq(1)
      expect(Notification.count).to eq(1)
      expect(Notification.first.donation_id).to eq(donation2.id)
    end

    it 'does not add a notification for a regular gift after a larger gift in same month' do
      donation.update(amount: 15, donation_date: Date.today.beginning_of_month)
      create(:donation, donor_account: donor_account, amount: 5,
                        designation_account: da, donation_date: Date.today.end_of_month)

      expect(larger_gift.check(account_list).size).to eq(1)
      expect(Notification.first.donation).to eq(donation)
    end

    it 'does not notify for a regular gift if an extra gift was given that month' do
      donation.update(amount: 15, donation_date: Date.today.beginning_of_month)
      expect(larger_gift.check(account_list).size).to eq(1)
      expect(Notification.first.donation).to eq(donation)

      create(:donation, donor_account: donor_account, amount: 5,
                        designation_account: da, donation_date: Date.today.end_of_month)
      expect(larger_gift.check(account_list)).to be_empty
    end
  end

  context '#caught_up_earlier_months?' do
    it 'does not error if first_donation_date is nil' do
      create(:donation, donor_account: donor_account,
                        designation_account: da, donation_date: Date.today << 1)
      contact.update(first_donation_date: nil)
      expect { larger_gift.caught_up_earlier_months?(contact) }.to_not raise_error
    end
  end
end
