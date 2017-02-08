require 'rails_helper'

describe DonationReports::ReceivedDonations do
  let(:all_scoper) { -> (donations) { donations } }
  let(:account_list) { create(:account_list) }
  let(:designation_account) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:received_donations) { DonationReports::ReceivedDonations.new(account_list: account_list, donations_scoper: all_scoper) }

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  describe '#donations' do
    it 'includes received donations info' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: 2, tendered_currency: 'EUR',
                        donation_date: Date.current)
      donations_info = received_donations.donations
      expect(donations_info.size).to eq 1
      expect(donations_info.first.likelihood_type).to eq 'received'
      expect(donations_info.first.contact_id).to eq contact.uuid
      expect(donations_info.first.amount).to eq 2
      expect(donations_info.first.currency).to eq 'EUR'
    end

    it 'falls back to currency and amount when tendered currency/amount nil' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: nil, tendered_currency: nil,
                        amount: 3, currency: 'GBP',
                        donation_date: Date.current)

      donations_info = received_donations.donations

      expect(donations_info.first.currency).to eq 'GBP'
      expect(donations_info.first.amount).to eq 3
    end
  end

  describe '#donors' do
    it 'includes donor info' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: 2, tendered_currency: 'EUR',
                        donation_date: Date.current)
      donors_info = received_donations.donors
      expect(donors_info.size).to eq 1
      expect(donors_info.first.contact_name).to eq contact.name
    end
  end

  context 'scoped to EUR' do
    let(:all_scoper) { -> (donations) { donations.where(currency: 'EUR') } }

    it 'excludes donations according to the given scoper' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: nil, tendered_currency: nil,
                        amount: 3, currency: 'GBP',
                        donation_date: Date.current)

      donations_info = received_donations.donations
      donors_info = received_donations.donors

      expect(donations_info).to be_empty
      expect(donors_info).to be_empty
    end
  end
end
