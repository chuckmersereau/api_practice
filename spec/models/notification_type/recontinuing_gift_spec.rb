require 'spec_helper'

describe NotificationType::RecontinuingGift do
  let!(:recontinuing_gift) { NotificationType::RecontinuingGift.first_or_initialize }
  let!(:da) { create(:designation_account) }
  let!(:account_list) { create(:account_list) }
  let!(:contact) { create(:contact, account_list: account_list, pledge_amount: 9.99, pledge_received: true) }
  let!(:donor_account) { create(:donor_account) }
  let!(:donation) { create(:donation, donor_account: donor_account, designation_account: da) }
  let!(:old_donation) do
    create(:donation, donor_account: donor_account, designation_account: da,
                      donation_date: Date.today << 3)
  end

  before do
    account_list.account_list_entries.create!(designation_account: da)
    contact.donor_accounts << donor_account
    contact.update_donation_totals(old_donation)
    contact.update_donation_totals(donation)
  end

  context '#check' do
    it 'adds a notification if a gift comes from a financial partner after a lag of 2 or more months' do
      expect(recontinuing_gift.check(account_list).size).to eq(1)
    end

    it 'does not add a notfication if the lag was just one month or there was no previous gift' do
      old_donation.update(donation_date: Date.today << 2)
      expect(recontinuing_gift.check(account_list)).to be_empty
      old_donation.destroy!
      expect(recontinuing_gift.check(account_list)).to be_empty
    end

    it 'does not add a notification if marked as pledge not received' do
      contact.update(pledge_received: false)
      expect(recontinuing_gift.check(account_list)).to be_empty
    end

    it 'does not notify if prior gift was a special gift', versioning: true do
      # These updates will create paper trail versions
      contact.update(status: 'Partner - Special')
      contact.update(status: 'Partner - Financial')

      # The last version will have the 'Partner - Special' so make all the
      # rest be old so that we simulate that the partner was a special partner
      # previously.
      contact.versions.where.not(id: contact.versions.last.id).destroy_all
      expect(contact.reload.version_at(old_donation.donation_date).status)
        .to eq('Partner - Special')

      # Now don't consider it a recontinuing gift because the partner
      # status at the previous gift time was not Partner - Financial
      expect(recontinuing_gift.check(account_list)).to be_empty
    end
  end
end
