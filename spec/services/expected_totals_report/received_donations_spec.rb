require 'rails_helper'

describe ExpectedTotalsReport::ReceivedDonations do
  subject { described_class.new(account_list: account_list) }
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let!(:designation_account_1) { create(:designation_account) }
  let!(:designation_account_2) { create(:designation_account) }
  let!(:donor_account_1) { create(:donor_account) }
  let!(:donor_account_2) { create(:donor_account) }
  let!(:contact_1) { create(:contact, account_list: account_list) }
  let!(:contact_2) { create(:contact, account_list: account_list) }

  let!(:donation_1) do
    create(:donation, donor_account: donor_account_1,
                      designation_account: designation_account_1,
                      amount: 3,
                      currency: 'CAD',
                      tendered_amount: 3,
                      tendered_currency: 'CAD',
                      donation_date: Date.current)
  end

  let!(:donation_2) do
    create(:donation, donor_account: donor_account_2,
                      designation_account: designation_account_2,
                      amount: 2,
                      currency: 'GBP',
                      tendered_amount: nil,
                      tendered_currency: nil,
                      donation_date: Date.current)
  end

  before do
    account_list.designation_accounts << designation_account_1
    account_list.designation_accounts << designation_account_2
    contact_1.donor_accounts << donor_account_1
    contact_2.donor_accounts << donor_account_2
  end

  describe '#donation_rows' do
    subject { described_class.new(account_list: account_list).donation_rows }

    it 'includes received donations with their contact info too' do
      expect(subject.size).to eq 2
      expect(subject).to contain_exactly(
        {
          type: 'received',
          contact: contact_1,
          donation_amount: 3.0,
          donation_currency: 'CAD'
        },
        type: 'received',
        contact: contact_2,
        donation_amount: 2.0,
        donation_currency: 'GBP'
      )
    end

    context 'designation_account_id present in filter_params' do
      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { designation_account_id: designation_account_1.id }
        ).donation_rows
      end

      it 'includes received donations with their contact info too' do
        expect(subject.size).to eq 1
        expect(subject).to contain_exactly(
          type: 'received',
          contact: contact_1,
          donation_amount: 3.0,
          donation_currency: 'CAD'
        )
      end
    end

    context 'donor_account_id present in filter_params' do
      subject do
        described_class.new(
          account_list: account_list,
          filter_params: { donor_account_id: donor_account_2.id }
        ).donation_rows
      end

      it 'includes received donations with their contact info too' do
        expect(subject.size).to eq 1
        expect(subject).to contain_exactly(
          type: 'received',
          contact: contact_2,
          donation_amount: 2.0,
          donation_currency: 'GBP'
        )
      end
    end
  end
end
