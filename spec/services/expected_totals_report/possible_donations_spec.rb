require 'rails_helper'

describe ExpectedTotalsReport::PossibleDonations do
  subject { described_class.new(account_list: account_list) }
  let(:account_list) { create(:account_list) }
  let(:designation_account_1) { create(:designation_account) }
  let(:designation_account_2) { create(:designation_account) }
  let(:donor_account_1) { create(:donor_account) }
  let(:donor_account_2) { create(:donor_account) }
  let(:contact_1) do
    create(:contact, account_list: account_list, pledge_amount: 2,
                     pledge_currency: 'EUR')
  end
  let(:contact_2) do
    create(:contact, account_list: account_list, pledge_amount: 4,
                     pledge_currency: 'CAD')
  end
  let!(:donation_1) do
    create(:donation, donor_account: donor_account_1,
                      designation_account: designation_account_1)
  end
  let!(:donation_2) do
    create(:donation, donor_account: donor_account_2,
                      designation_account: designation_account_2)
  end

  before do
    account_list.designation_accounts << designation_account_1
    account_list.designation_accounts << designation_account_2
    contact_1.donor_accounts << donor_account_1
    contact_2.donor_accounts << donor_account_2
  end

  describe '#donation_rows' do
    subject { described_class.new(account_list: account_list).donation_rows }

    let(:likely_donation) do
      instance_double(
        ExpectedTotalsReport::LikelyDonation,
        likely_more: likely_more,
        received_this_month: received_this_month
      )
    end

    before do
      allow(ExpectedTotalsReport::LikelyDonation).to receive(:new) { likely_donation }
    end

    context 'likely amount is more than zero' do
      let(:likely_more) { 0 }
      let(:received_this_month) { 0 }

      it 'reports unlikely donations' do
        expect(subject.size).to eq 2
        expect(subject).to contain_exactly(
          {
            type: 'unlikely',
            contact: contact_1,
            donation_amount: 2.0,
            donation_currency: contact_1.pledge_currency
          },
          type: 'unlikely',
          contact: contact_2,
          donation_amount: 4.0,
          donation_currency: contact_2.pledge_currency
        )
      end

      context 'designation_account_id present in filter_params' do
        subject do
          described_class.new(
            account_list: account_list,
            filter_params: { designation_account_id: designation_account_1.id }
          ).donation_rows
        end

        it 'reports unlikely donations' do
          expect(subject.size).to eq 1
          expect(subject).to contain_exactly(
            type: 'unlikely',
            contact: contact_1,
            donation_amount: 2.0,
            donation_currency: contact_1.pledge_currency
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

        it 'reports unlikely donations' do
          expect(subject.size).to eq 1
          expect(subject).to contain_exactly(
            type: 'unlikely',
            contact: contact_2,
            donation_amount: 4.0,
            donation_currency: contact_2.pledge_currency
          )
        end
      end
    end

    context 'likely amount is more than zero' do
      let(:likely_more) { 1 }
      let(:received_this_month) { 0 }

      it 'reports likely donations' do
        expect(subject.size).to eq 2
        expect(subject).to contain_exactly(
          {
            type: 'likely',
            contact: contact_1,
            donation_amount: 1.0,
            donation_currency: contact_1.pledge_currency
          },
          type: 'likely',
          contact: contact_2,
          donation_amount: 1.0,
          donation_currency: contact_2.pledge_currency
        )
      end

      context 'designation_account_id present in filter_params' do
        subject do
          described_class.new(
            account_list: account_list,
            filter_params: { designation_account_id: designation_account_1.id }
          ).donation_rows
        end

        it 'reports likely donations' do
          expect(subject.size).to eq 1
          expect(subject).to contain_exactly(
            type: 'likely',
            contact: contact_1,
            donation_amount: 1.0,
            donation_currency: contact_1.pledge_currency
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

        it 'reports unlikely donations' do
          expect(subject.size).to eq 1
          expect(subject).to contain_exactly(
            type: 'likely',
            contact: contact_2,
            donation_amount: 1.0,
            donation_currency: contact_2.pledge_currency
          )
        end
      end
    end

    context 'donation already received this month' do
      let(:likely_more) { 0 }
      let(:received_this_month) { 2 }

      it 'reports nothing' do
        expect(subject).to be_empty
      end
    end
  end
end
