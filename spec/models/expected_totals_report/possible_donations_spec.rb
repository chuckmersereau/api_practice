require 'spec_helper'

module ExpectedTotalsReport
  describe PossibleDonations, '#donation_rows' do
    let(:account_list) { create(:account_list) }
    let(:designation_account) { create(:designation_account) }
    let(:donor_account) { create(:donor_account) }
    let(:contact) do
      create(:contact, account_list: account_list, pledge_amount: 2,
                       pledge_currency: 'EUR')
    end
    let!(:donation) do
      create(:donation, donor_account: donor_account,
                        designation_account: designation_account)
    end

    before do
      account_list.designation_accounts << designation_account
      contact.donor_accounts << donor_account
    end

    it 'reports an unlikely donation if likely amount is zero' do
      likely_donation = instance_double(LikelyDonation, received_this_month: 0,
                                                        likely_more: 0)
      allow(LikelyDonation).to receive(:new) do |params|
        expect(params[:contact]).to eq contact
        expect(params[:recent_donations].to_a).to eq [donation]
        expect(params[:date_in_month]).to eq Date.current
        likely_donation
      end

      rows = PossibleDonations.new(account_list).donation_rows

      expect(rows.size).to eq 1
      expect(rows.first).to eq(type: 'unlikely', contact: contact,
                               donation_amount: contact.pledge_amount,
                               donation_currency: contact.pledge_currency)
    end

    it 'reports likely donation if likely amount is more than zero' do
      likely_more = 1
      likely_donation = instance_double(LikelyDonation, received_this_month: 0,
                                                        likely_more: likely_more)
      allow(LikelyDonation).to receive(:new) { likely_donation }

      rows = PossibleDonations.new(account_list).donation_rows

      expect(rows.size).to eq 1
      expect(rows.first).to eq(type: 'likely', contact: contact,
                               donation_amount: likely_more,
                               donation_currency: contact.pledge_currency)
    end

    it 'reports nothing if donation already received this month' do
      likely_donation = instance_double(LikelyDonation, likely_more: 0,
                                                        received_this_month: 2)
      allow(LikelyDonation).to receive(:new) { likely_donation }

      rows = PossibleDonations.new(account_list).donation_rows

      expect(rows).to be_empty
    end
  end
end
