require 'rails_helper'

RSpec.describe Reports::ExpectedMonthlyTotals, type: :model do
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
  let!(:contact_with_pledge) { create(:contact, account_list: account_list, pledge_amount: 50) }

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

  describe '#expected_donations' do
    subject do
      described_class.new(
        account_list: account_list
      ).expected_donations
    end

    it 'returns donations infos' do
      expect(subject).to be_a(Array)
      expect(subject.size).to eq(2)
      expect(subject.first[:contact_name]).to eq(contact.name)
    end

    it 'returns received donations' do
      expect(subject.detect { |hash| hash[:type] == 'received' }).to be_present
    end

    it 'returns possible donations' do
      expect(subject.detect { |hash| hash[:type] == 'unlikely' }).to be_present
    end

    context 'designation_account_id present in filter_params' do
      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { designation_account_id: designation_account_1.id }
        ).expected_donations
      end

      it 'returns donations infos' do
        expect(subject).to be_a(Array)
        expect(subject.size).to eq(1)
        expect(subject.first[:contact_name]).to eq(contact.name)
      end

      it 'returns received donations' do
        expect(subject.detect { |hash| hash[:type] == 'received' }).to be_nil
      end

      it 'returns possible donations' do
        expect(subject.detect { |hash| hash[:type] == 'unlikely' }).to be_present
      end
    end

    context 'donor_account_id present in filter_params' do
      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { donor_account_id: donor_account_2.id }
        ).expected_donations
      end

      it 'returns donations infos' do
        expect(subject).to be_a(Array)
        expect(subject.size).to eq(1)
        expect(subject.first[:contact_name]).to eq(contact.name)
      end

      it 'returns received donations' do
        expect(subject.detect { |hash| hash[:type] == 'received' }).to be_present
      end

      it 'returns possible donations' do
        expect(subject.detect { |hash| hash[:type] == 'unlikely' }).to be_nil
      end
    end
  end

  describe '#total_currency' do
    it 'returns total_currency' do
      expect(subject.total_currency).to eq('USD')
    end
  end

  describe '#total_currency_symbol' do
    it 'returns total_currency_symbol' do
      expect(subject.total_currency_symbol).to eq('$')
    end
  end
end
