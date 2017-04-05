require 'rails_helper'

RSpec.describe Reports::DonorCurrencyDonations, type: :model do
  let!(:report) { Reports::DonorCurrencyDonations.new(account_list: account_list) }

  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:designation_account) { create(:designation_account) }
  let!(:donor_account) { create(:donor_account) }
  let!(:contact) { create(:contact, account_list: account_list) }

  let!(:cad_donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      tendered_amount: 3, tendered_currency: 'CAD',
                      donation_date: Date.current - 1.month)
  end

  let!(:eur_donation) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      tendered_amount: 2, tendered_currency: 'EUR',
                      donation_date: Date.current)
  end

  let!(:donation_last_year) do
    create(:donation, donor_account: donor_account,
                      designation_account: designation_account,
                      tendered_amount: 88, tendered_currency: 'EUR',
                      donation_date: 13.months.ago.end_of_month - 1.day)
  end

  before do
    account_list.designation_accounts << designation_account
    contact.donor_accounts << donor_account
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(report).to be_a(Reports::DonorCurrencyDonations)
      expect(report.account_list).to eq(account_list)
    end
  end

  describe '#donor_infos' do
    it 'returns donor infos' do
      expect(report.donor_infos).to be_a(Array)
      expect(report.donor_infos.size).to eq(1)
      expect(report.donor_infos.first).to be_a(DonationReports::DonorInfo)
      expect(report.donor_infos.first.contact_name).to eq(contact.name)
    end
  end

  describe '#months' do
    it { expect(report.months.size).to eq 13 }
    it { report.months.each { |m| expect(m).to be_a Date } }
  end

  describe '#currency_groups' do
    subject { report.currency_groups }
    let(:cad) { subject['CAD'] }
    let(:totals) { cad[:totals] }
    let(:donation_months) { cad[:donation_infos].flat_map { |d| d[:months] } }

    it { expect(totals[:year]).to eq 3 }

    it 'should sum donations by months' do
      expect(totals[:months].select { |m| m == 0 }.size).to eq 12
      expect(totals[:months].select { |m| m == 3 }.size).to eq 1
    end

    it 'should include each donation record' do
      all_donations = donation_months.flat_map { |m| m[:donations] }
      match = all_donations.find { |d| d.donation_id == cad_donation.uuid }

      expect(match).to be_present
      expect(match).to be_a DonationReports::DonationInfo
    end

    it 'does not return donations made more than 12 months ago' do
      subject.each do |_, report|
        report[:donation_infos].flat_map { |d| d[:months] }.each do |month|
          expect(month[:donations].find { |d| d.donation_id == donation_last_year.uuid }).to be_nil
        end
      end
    end
  end

  describe '#currency_groups hash structure' do
    subject { report.currency_groups }

    it { expect(subject).to be_a Hash }

    it 'has the correct key/value structure' do
      expect(subject.keys).to include 'CAD', 'EUR'

      subject.each do |_, h|
        expect(h.keys).to include :totals, :donation_infos
        expect(h[:totals].keys).to include :year, :months

        expect(h[:donation_infos]).not_to be_empty
        h[:donation_infos].each do |info|
          expect(info).to include :contact_id, :total, :average, :minimum,
                                  :maximum, :months

          info[:months].each do |month|
            expect(month.keys).to include :total, :donations
          end
        end
      end
    end
  end
end
