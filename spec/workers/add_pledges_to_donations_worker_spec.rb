require 'rails_helper'

RSpec.describe AddPledgesToDonationsWorker do
  describe '#perform' do
    context 'donation has no appeal' do
      let!(:donation) { create(:donation) }

      it 'should not create pledges' do
        expect { described_class.new.perform }.to_not change { Pledge.count }
      end
    end

    context 'donation has appeal' do
      let!(:account_list) { create(:account_list) }
      let!(:appeal) { create(:appeal, account_list: account_list) }
      let!(:donation) { create(:donation, appeal: appeal) }

      context 'appeal has no account_list' do
        before { appeal.update(account_list: nil) }

        it 'should not create pledges' do
          expect { described_class.new.perform }.to_not change { Pledge.count }
        end
      end

      context 'donation donor_account which belongs to contact on account list' do
        let!(:donor_account) { create(:donor_account) }
        let!(:contact) { create(:contact, account_list: account_list) }
        before { donor_account.contacts << contact }
        let!(:donation) { create(:donation, appeal: appeal, donor_account: donor_account) }

        it 'should create pledges' do
          expect { described_class.new.perform }.to change { Pledge.count }.by(1)
          pledge = Pledge.first
          expect(pledge.amount).to eq donation.amount
          expect(pledge.appeal).to eq appeal
          expect(pledge.contact).to eq contact
          expect(pledge.donations).to eq [donation]
          expect(pledge.expected_date).to eq donation.donation_date
        end
        context 'donation has appeal amount' do
          before { donation.update(amount: 100, appeal_amount: 50) }

          it 'should create pledges with appeal amount' do
            described_class.new.perform
            pledge = Pledge.first
            expect(pledge.amount).to eq donation.appeal_amount
          end
        end
      end

      context 'contact has two donations on appeal' do
        let!(:donor_account) { create(:donor_account) }
        let!(:contact) { create(:contact, account_list: account_list) }
        before { donor_account.contacts << contact }
        let!(:donation1) { create(:donation, donor_account: donor_account) }
        let!(:donation2) { create(:donation, donor_account: donor_account) }

        it 'should create pledges' do
          donor_account.donations.update_all(appeal_id: appeal.id)

          expect { described_class.new.perform }.to change { Pledge.count }.by(1)
          pledge = Pledge.first
          expect(pledge.amount).to eq(donation1.amount + donation2.amount)
          expect(pledge.donations).to match_array [donation1, donation2]
        end
      end
    end
  end
end
