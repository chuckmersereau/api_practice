require 'spec_helper'

module DonationReports
  describe ReceivedDonations, '#donor_and_donation_info' do
    let(:account_list) { create(:account_list) }
    let(:designation_account) { create(:designation_account) }
    let(:donor_account) { create(:donor_account) }
    let(:contact) { create(:contact, account_list: account_list) }
    before do
      account_list.designation_accounts << designation_account
      contact.donor_accounts << donor_account
    end

    it 'includes received donations with their contact info too' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: 2, tendered_currency: 'EUR',
                        donation_date: Date.current)
      all_scoper = -> (donations) { donations }

      donations_info, donors_info =
        ReceivedDonations
        .new(account_list: account_list, donations_scoper: all_scoper)
        .donor_and_donation_info

      expect(donors_info.size).to eq 1
      expect(donors_info.first.name).to eq contact.name
      expect(donations_info.size).to eq 1
      expect(donations_info.first.liklihood_type).to eq 'received'
      expect(donations_info.first.contact_id).to eq contact.id
      expect(donations_info.first.amount).to eq 2
      expect(donations_info.first.currency).to eq 'EUR'
    end

    it 'falls back to currency and amount when tendered currency/amount nil' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: nil, tendered_currency: nil,
                        amount: 3, currency: 'GBP',
                        donation_date: Date.current)
      all_scoper = -> (donations) { donations }

      donations_info, _donors_info =
        ReceivedDonations
        .new(account_list: account_list, donations_scoper: all_scoper)
        .donor_and_donation_info

      expect(donations_info.first.currency).to eq 'GBP'
      expect(donations_info.first.amount).to eq 3
    end

    it 'excludes donations according to the given scoper' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: nil, tendered_currency: nil,
                        amount: 3, currency: 'GBP',
                        donation_date: Date.current)
      all_scoper = -> (donations) { donations.where(currency: 'EUR') }

      donations_info, donors_info =
        ReceivedDonations
        .new(account_list: account_list, donations_scoper: all_scoper)
        .donor_and_donation_info

      expect(donations_info).to be_empty
      expect(donors_info).to be_empty
    end
  end
end
