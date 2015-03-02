require 'spec_helper'

describe ContactDonationMethods do
  let!(:da) { create(:designation_account) }
  let!(:account_list) { create(:account_list) }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:donor_account) { create(:donor_account) }
  let!(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }
  let(:old_donation) do
    create(:donation, donor_account: donor_account, designation_account: da,
                      donation_date: Date.today << 3)
  end

  before do
    account_list.account_list_entries.create!(designation_account: da)
    contact.donor_accounts << donor_account
    contact.update_donation_totals(donation)
    contact.update_donation_totals(old_donation)
  end

  context '#designated_donations' do
    it 'gives donations whose designation is connected to the contact account list' do
      expect(contact.designated_donations.to_a).to eq([donation, old_donation])
      donation.update(designation_account: nil)
      old_donation.update(donor_account: nil)
      expect(contact.designated_donations).to be_empty
    end
  end

  context '#last_donation' do
    it 'returns the latest designated donation' do
      old_donation
      expect(contact.last_donation).to eq(donation)
      donation.update(designation_account: nil)
      expect(contact.last_donation).to eq(old_donation)
    end
  end

  context '#last_monthly_total' do
    it 'returns zero with no error if there are no donations' do
      Donation.destroy_all
      contact.update(last_donation_date: nil)
      expect(contact.last_monthly_total).to eq(0)
    end

    it 'returns the total of the current month if it has a donation' do
      expect(contact.last_monthly_total).to eq(9.99)
    end

    it 'returns the total of the previous month if current month has no donations' do
      contact.update(last_donation_date: nil)
      donation.update(donation_date: Date.today << 1)
      old_donation.update(donation_date: Date.today << 1)
      contact.update_donation_totals(donation)
      contact.update_donation_totals(old_donation)
      expect(contact.last_monthly_total).to eq(9.99  * 2)
    end

    it 'returns zero if the previous and current months have no donations' do
      contact.update(last_donation_date: nil)
      donation.update(donation_date: Date.today << 2)
      old_donation.update(donation_date: Date.today << 2)
      contact.update_donation_totals(donation)
      contact.update_donation_totals(old_donation)
      expect(contact.last_monthly_total).to eq(0)
    end
  end

  context '#prev_month_donation_date' do
    it 'returns nil if there are no donations' do
      Donation.destroy_all
      expect(contact.prev_month_donation_date).to be_nil
      contact.update(last_donation_date: nil)
      expect(contact.prev_month_donation_date).to be_nil
    end

    it 'returns the donation date of the donation before this month if this month has donations' do
      expect(contact.prev_month_donation_date).to eq(old_donation.donation_date)
    end

    it 'returns the donation date of the donation before last month if this month has no donations' do
      contact.update(last_donation_date: nil)
      donation.update(donation_date: Date.today << 1)
      contact.update_donation_totals(donation)
      expect(contact.prev_month_donation_date).to eq(old_donation.donation_date)
    end
  end

  context '#recent_monthly_avg' do
    it 'uses time between donations to calculate average' do
      expect(contact.recent_monthly_avg).to eq(9.99 / 2)
    end

    it 'considers pledge frequency in the average' do
      contact.update(pledge_frequency: 12)
      expect(contact.recent_monthly_avg).to eq(9.99 * 2 / 12)
    end
  end

  context '#months_from_prev_to_last_donation' do
    it 'gives the months elapsed between the last donation and the last donation in a previous month' do
      expect(contact.months_from_prev_to_last_donation).to eq(3)
    end
  end
end
