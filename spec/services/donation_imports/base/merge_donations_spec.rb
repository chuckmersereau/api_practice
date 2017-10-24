require 'rails_helper'

RSpec.describe DonationImports::Base::MergeDonations do
  describe 'initialize' do
    it 'initializes' do
      expect(described_class.new([])).to be_a(described_class)
    end
  end

  describe '#merge' do
    let!(:account_list) { create(:account_list) }
    let!(:donor_account)  { create(:donor_account, total_donations: 0) }
    let!(:designation_account) { create(:designation_account).tap { |da| da.account_lists << account_list } }
    let!(:contact) { create(:contact, account_list: account_list, total_donations: 0).tap { |c| c.donor_accounts << donor_account } }

    let!(:donation_one) do
      create(:donation, appeal_id: 1, tnt_id: nil, motivation: nil, amount: 1.0, donation_date: Date.new,
                        donor_account: donor_account, designation_account: designation_account)
    end
    let!(:donation_two) do
      create(:donation, appeal_id: nil, tnt_id: '2', motivation: nil, amount: 1.0, donation_date: Date.new,
                        donor_account: donor_account, designation_account: designation_account)
    end
    let!(:donation_three) do
      create(:donation, appeal_id: nil, tnt_id: '2', motivation: 'Motivation', amount: 1.0, donation_date: Date.new,
                        donor_account: donor_account, designation_account: designation_account)
    end
    let!(:other_donation) { create(:donation, amount: 1.0, donor_account: donor_account, designation_account: designation_account) }

    it 'returns if the donations has one or zero elements' do
      expect do
        expect(described_class.new([donation_one]).merge).to eq(donation_one)
        expect(described_class.new([]).merge).to eq(nil)
      end.to_not change { Donation.count }.from(4)
    end

    it 'merges the donations' do
      expect do
        expect(described_class.new([donation_one, donation_two, donation_three]).merge).to eq(donation_one)
      end.to change { Donation.count }.from(4).to(2)
      expect(donation_one.reload.appeal_id).to eq(1)
      expect(donation_one.tnt_id).to eq('2')
      expect(donation_one.motivation).to eq('Motivation')
    end

    it 'resets the donor account donation totals' do
      expect(donor_account.reload.total_donations).to eq(4)
      described_class.new([donation_one, donation_two, donation_three]).merge
      expect(donor_account.reload.total_donations).to eq(2)
    end

    it 'resets the contact donation totals' do
      expect(contact.reload.total_donations).to eq(4)
      described_class.new([donation_one, donation_two, donation_three]).merge
      expect(contact.reload.total_donations).to eq(2)
    end
  end
end
