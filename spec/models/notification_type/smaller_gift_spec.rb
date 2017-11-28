require 'rails_helper'

describe NotificationType::SmallerGift do
  let!(:smaller_gift) { NotificationType::SmallerGift.first_or_initialize }
  let!(:da) { create(:designation_account) }
  let!(:account_list) { create(:account_list) }
  let!(:contact) { create(:contact, account_list: account_list, pledge_amount: 15) }
  let!(:donor_account) { create(:donor_account) }
  let!(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }

  before do
    account_list.account_list_entries.create!(designation_account: da)
    contact.donor_accounts << donor_account
    contact.update_donation_totals(donation)
  end

  context '#check' do
    it 'adds a notification if a gift comes from a financial partner and is less than the pledge' do
      expect(smaller_gift.check(account_list).size).to eq(1)
    end

    it 'does not add a notfication if two small gifts add up to at least pledge come in at same time' do
      create(:donation, donor_account: donor_account, designation_account: da,
                        donation_date: Date.today)
      expect(smaller_gift.check(account_list)).to be_empty
    end

    it 'does not experience rounding errors' do
      contact.update(pledge_amount: 250, pledge_frequency: 3.0)
      donation.update(amount: 250.0, tendered_amount: 250.0)
      expect(smaller_gift.check(account_list).size).to eq(0)
    end

    it 'does not add a notification if the correct size gift comes in' do
      contact.update(pledge_amount: 1200.0, pledge_frequency: 12.0)
      donation.update(amount: 1200.0, tendered_amount: 1200.0)
      contact.update_donation_totals(donation)
      contact.update(first_donation_date: nil, last_donation_date: nil) # sometimes these aren't set
      expect(smaller_gift.check(account_list)).to be_empty
    end

    it 'does not raise an error if all donations are by GIFT_AID' do
      contact.update!(pledge_frequency: 0.5)
      donation.update!(payment_method: Donation::GIFT_AID)

      expect do
        expect(smaller_gift.check(account_list)).to be_empty
      end.not_to raise_error NoMethodError
    end
  end
end
