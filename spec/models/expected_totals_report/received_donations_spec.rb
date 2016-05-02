require 'spec_helper'

module ExpectedTotalsReport
  describe ReceivedDonations, '#donation_rows' do
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

      rows = ReceivedDonations.new(account_list).donation_rows

      expect(rows.size).to eq 1
      expect(rows.first).to eq(type: 'received', contact: contact,
                               donation_amount: 2, donation_currency: 'EUR')
    end

    it 'falls back to currency and amount when tendered currency/amount nil' do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account,
                        tendered_amount: nil, tendered_currency: nil,
                        amount: 3, currency: 'GBP',
                        donation_date: Date.current)

      rows = ReceivedDonations.new(account_list).donation_rows

      expect(rows.size).to eq 1
      expect(rows.first).to eq(type: 'received', contact: contact,
                               donation_amount: 3, donation_currency: 'GBP')
    end
  end
end
