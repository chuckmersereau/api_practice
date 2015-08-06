require 'spec_helper'

describe Donation do
  let(:donation) { create(:donation, donation_date: Date.new(2015, 4, 5)) }

  context '#localized_date' do
    it 'is just date' do
      expect(donation.localized_date).to eq 'April 05, 2015'
    end
  end

  context 'add_appeal_contacts' do
    let(:appeal) { create(:appeal) }

    it 'adds a contact to the appeal if that contacts donation is added' do
      contact = create(:contact, account_list: appeal.account_list)
      contact.donor_accounts << donation.donor_account
      donation.update(appeal: appeal, appeal_amount: 1)
      expect(appeal.contacts.reload).to include(contact)
    end

    it "doesn't adds a contact to the appeal if that contact is in different account list" do
      account_list = create(:account_list)
      contact = create(:contact, account_list: account_list)
      contact.donor_accounts << donation.donor_account
      donation.update(appeal: appeal, appeal_amount: 1)
      expect(appeal.contacts.reload).to_not include(contact)
    end

    it "doesn't adds a contact to the appeal if that contact is in different donor account" do
      contact = create(:contact, account_list: appeal.account_list)
      contact.donor_accounts << create(:donor_account)
      donation.update(appeal: appeal, appeal_amount: 1)
      expect(appeal.contacts.reload).to_not include(contact)
    end

    it "doesn't adds a contact to the appeal if that contact is in different donor account" do
      contact = create(:contact, account_list: appeal.account_list)
      donor_account = create(:donor_account)
      contact.donor_accounts << donor_account
      new_donation = create(:donation, appeal: appeal, appeal_amount: 1, donor_account_id: donor_account.id)
      expect(new_donation.donor_account).to eq(contact.donor_accounts.first)
      expect(appeal.contacts.reload).to include(contact)
    end
  end
end
