require 'rails_helper'

RSpec.describe Reports::SalaryCurrencyDonations, type: :model do
  subject { described_class.new(account_list: account_list) }

  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:designation_account_1) { create(:designation_account) }
  let!(:designation_account_2) { create(:designation_account) }
  let!(:designation_account_3) { create(:designation_account) }
  let!(:donor_account_1) { create(:donor_account) }
  let!(:donor_account_2) { create(:donor_account) }
  let!(:donor_account_3) { create(:donor_account) }
  let!(:contact) { create(:contact, account_list: account_list) }

  let!(:cad_donation) do
    create(:donation, donor_account: donor_account_1,
                      designation_account: designation_account_1,
                      amount: 3, currency: 'CAD',
                      donation_date: Date.current - 1.month)
  end

  let!(:eur_donation) do
    create(:donation, donor_account: donor_account_2,
                      designation_account: designation_account_2,
                      amount: 2, currency: 'EUR',
                      donation_date: Date.current)
  end

  let!(:donation_last_year) do
    create(:donation, donor_account: donor_account_3,
                      designation_account: designation_account_3,
                      amount: 88, currency: 'EUR',
                      donation_date: 13.months.ago.end_of_month - 1.day)
  end

  before do
    account_list.designation_accounts << designation_account_1
    account_list.designation_accounts << designation_account_2
    account_list.designation_accounts << designation_account_3
    contact.donor_accounts << donor_account_1
    contact.donor_accounts << donor_account_2
    contact.donor_accounts << donor_account_3
  end

  describe '#donor_infos' do
    it 'returns donor infos' do
      expect(subject.donor_infos).to be_a(Array)
      expect(subject.donor_infos.size).to eq(1)
      expect(subject.donor_infos.first).to be_a(DonationReports::DonorInfo)
      expect(subject.donor_infos.first.contact_name).to eq(contact.name)
    end
  end

  describe '#months' do
    it { expect(subject.months.size).to eq 13 }
    it { subject.months.each { |m| expect(m).to be_a Date } }
  end

  describe '#currency_groups' do
    subject { described_class.new(account_list: account_list).currency_groups }
    let(:usd) { subject['USD'] }
    let(:totals) { usd[:totals] }
    let(:donation_months) { usd[:donation_infos].flat_map { |d| d[:months] } }

    it { expect(totals[:year]).to eq 5 }

    it 'should sum donations by months' do
      expect(totals[:months].select(&:zero?).size).to eq 11
      expect(totals[:months].select(&:nonzero?).size).to eq 2
    end

    it 'should include each donation record' do
      all_donations = donation_months.flat_map { |m| m[:donations] }
      match = all_donations.find { |d| d.donation_id == cad_donation.id }

      expect(match).to be_present
      expect(match).to be_a DonationReports::DonationInfo
    end

    it 'does not return donations made more than 12 months ago' do
      subject.each do |_, report|
        report[:donation_infos].flat_map { |d| d[:months] }.each do |month|
          expect(month[:donations].find { |d| d.donation_id == donation_last_year.id }).to be_nil
        end
      end
    end

    context 'can allow custom start and end date for donation viewing' do
      let(:starting) { Date.today - 3.years }
      let(:ending) { Date.today - 1.year }

      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { month_range: (starting..ending) }
        )
      end

      it 'should have the correct start date' do
        expect(subject.start_date).to eq(starting.beginning_of_month)
      end

      it 'should have the correct end date' do
        expect(subject.end_date).to eq(ending)
      end
    end

    context 'designation_account_id present in filter_params' do
      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { designation_account_id: designation_account_1.id }
        ).currency_groups
      end

      it 'should include each donation record' do
        all_donations = donation_months.flat_map { |m| m[:donations] }
        match = all_donations.first
        expect(all_donations.length).to eq 1
        expect(match).to be_a DonationReports::DonationInfo
        expect(match.donation_id).to eq cad_donation.id
      end
    end

    context 'donor_account_id present in filter_params' do
      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { donor_account_id: donor_account_1.id }
        ).currency_groups
      end

      it 'should include each donation record' do
        all_donations = donation_months.flat_map { |m| m[:donations] }
        match = all_donations.first
        expect(all_donations.length).to eq 1
        expect(match).to be_a DonationReports::DonationInfo
        expect(match.donation_id).to eq cad_donation.id
      end
    end
  end

  describe '#currency_groups hash structure' do
    subject { described_class.new(account_list: account_list).currency_groups }

    it { expect(subject).to be_a Hash }

    it 'has the correct key/value structure' do
      expect(subject.keys.size).to eq 1
      expect(subject.keys).to include 'USD'

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
          expect(info[:months].last[:donations].first.attributes.keys).to include :converted_amount, :converted_currency
        end
      end
    end
  end
end
