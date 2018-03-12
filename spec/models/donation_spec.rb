require 'rails_helper'

describe Donation do
  let(:designation_account) { create(:designation_account) }
  let(:donation) { create(:donation, donation_date: Date.new(2015, 4, 5), designation_account: designation_account) }

  describe '#localized_date' do
    it 'is just date' do
      expect(donation.localized_date).to eq 'April 05, 2015'
    end
  end

  describe '#update_contacts' do
    let(:contact) { create(:contact) }
    let(:donor_account) { create(:donor_account, contacts: [contact]) }

    context 'donor_account_id is updated' do
      let(:donation) { create(:donation, designation_account: designation_account, donor_account: donor_account) }
      let(:new_contact) { create(:contact) }
      let(:new_donor_account) { create(:donor_account, contacts: [new_contact]) }

      it 'updates old donor account contacts and new donor account contacts' do
        allow(DonorAccount).to receive(:find).with(donor_account.id).and_return(donor_account)
        expect(contact).to receive(:save).once
        allow(donation).to receive(:contacts).and_return([new_contact])
        expect(new_contact).to receive(:save).once
        donation.update(donor_account: new_donor_account)
      end
    end

    context 'donor_account_id is added' do
      let(:donation) { create(:donation, designation_account: designation_account, donor_account: nil) }

      it 'updates donor account contacts' do
        expect_any_instance_of(Contact).to receive(:save).once.and_call_original
        donation.update(donor_account: donor_account)
      end
    end
  end

  describe '#update_related_pledge' do
    let(:pledge)   { create(:pledge, amount: 100.00) }
    let(:donation) { build(:donation, appeal: create(:appeal)) }
    let!(:persisted_donation) { create(:donation) }

    it 'calls the match service method whenever a new donation is created' do
      expect_any_instance_of(AccountList::PledgeMatcher).to receive(:needs_pledge?).and_return(true)
      expect_any_instance_of(AccountList::PledgeMatcher).to receive(:pledge).and_return(pledge)
      donation.save
      expect(pledge.donations.count).to eq(1)
      expect(pledge.donations).to include(donation)
    end

    it "doesn't call the match service method whenever a new donation is updated" do
      expect_any_instance_of(AccountList::PledgeMatcher).not_to receive(:pledge)
      persisted_donation.update(amount: 200.00)
    end

    it 'deletes pledge donation if appeal is removed' do
      expect_any_instance_of(AccountList::PledgeMatcher).to receive(:needs_pledge?).and_return(true)
      expect_any_instance_of(AccountList::PledgeMatcher).to receive(:pledge).and_return(pledge)
      donation.save

      expect { donation.update(appeal: nil) }.to change(PledgeDonation, :count).by(-1)
    end
  end

  context 'converted_amount and converted_currency' do
    let(:designation_account) { create(:designation_account) }
    let(:donation) { create(:donation, currency: 'EUR', designation_account: designation_account) }
    let!(:currency_rate) { create(:currency_rate, exchanged_on: donation.donation_date) }

    it 'returns the converted amount to designation_account currency' do
      expect(donation.converted_amount).to be_within(0.001).of(donation.amount / currency_rate.rate)
    end

    it 'returns the converted designation_account currency' do
      expect(donation.converted_currency).to eq('USD')
    end
  end

  describe '#add_appeal_contacts' do
    let(:appeal) { create(:appeal) }

    it 'adds a contact to the appeal if that contacts donation is added' do
      contact = create(:contact, account_list: appeal.account_list, appeals: [appeal])
      contact.donor_accounts << donation.donor_account
      donation.update(appeal: appeal, appeal_amount: 1)
      expect(appeal.contacts.reload).to include(contact)
    end

    it "doesn't adds a contact to the appeal if that contact is in different donor account" do
      contact = create(:contact, account_list: appeal.account_list)
      contact.donor_accounts << create(:donor_account)
      donation.update(appeal: appeal, appeal_amount: 1)
      expect(appeal.contacts.reload).to_not include(contact)
    end

    it "doesn't adds a contact to the appeal if that contact is in different donor account" do
      contact = create(:contact, account_list: appeal.account_list, appeals: [appeal])
      donor_account = create(:donor_account)
      contact.donor_accounts << donor_account
      new_donation = create(:donation, appeal: appeal, appeal_amount: 1, donor_account_id: donor_account.id)
      expect(new_donation.donor_account).to eq(contact.donor_accounts.first)
      expect(appeal.contacts.reload).to include(contact)
    end
  end

  context '.all_from_offline_orgs?' do
    it 'returns true if all donations are from offline orgs' do
      org = create(:organization, api_class: 'OfflineOrg')
      donor_account = create(:donor_account, organization: org)
      create(:donation, donor_account: donor_account)

      expect(Donation.all_from_offline_orgs?(Donation.all)).to be true
    end

    it 'returns false if any donation is from an online org' do
      offline_org = create(:organization, api_class: 'OfflineOrg')
      da_offline = create(:donor_account, organization: offline_org)
      create(:donation, donor_account: da_offline)
      online_org = create(:organization, api_class: 'Siebel')
      da_online = create(:donor_account, organization: online_org)
      create(:donation, donor_account: da_online)

      expect(Donation.all_from_offline_orgs?(Donation.all)).to be false
    end
  end

  describe 'after_destroy #reset_totals' do
    let!(:account_list) { create(:account_list) }
    let!(:donor_account) { create(:donor_account, total_donations: 0) }
    let!(:designation_account) { create(:designation_account).tap { |da| da.account_lists << account_list } }
    let!(:contact) do
      create(:contact, account_list: account_list, total_donations: 0).tap { |c| c.donor_accounts << donor_account }
    end
    let!(:donation_one) do
      create(:donation, amount: 1, donor_account: donor_account, designation_account: designation_account)
    end
    let!(:donation_two) do
      create(:donation, amount: 2, donor_account: donor_account, designation_account: designation_account)
    end
    let!(:donation_three) do
      create(:donation, amount: 3, donor_account: donor_account, designation_account: designation_account)
    end

    it 'resets the donor account total_donations' do
      expect(donor_account.total_donations).to eq(6)
      donation_one.destroy
      expect(donor_account.reload.total_donations).to eq(5)
      donation_two.destroy
      expect(donor_account.reload.total_donations).to eq(3)
      donation_three.destroy
      expect(donor_account.reload.total_donations).to eq(0)
    end

    it 'resets the designation account total_donations' do
      expect(contact.reload.total_donations).to eq(6)
      donation_one.destroy
      expect(contact.reload.total_donations).to eq(5)
      donation_two.destroy
      expect(contact.reload.total_donations).to eq(3)
      donation_three.destroy
      expect(contact.reload.total_donations).to eq(0)
    end
  end
end
