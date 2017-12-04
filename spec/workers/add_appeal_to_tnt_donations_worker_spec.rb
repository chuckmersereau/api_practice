require 'rails_helper'

RSpec.describe AddAppealToTntDonationsWorker do
  describe '#perform' do
    let(:account_list) { create(:account_list) }
    let(:contact) { create(:contact, account_list: account_list) }
    let(:donor_account) { create(:donor_account, contacts: [contact], account_number: '432294333') }
    let(:designation) { create(:designation_account, account_lists: [account_list]) }
    let(:import) { create(:tnt_import_3_0_appeals, account_list: account_list) }
    let!(:appeal) { create(:appeal, account_list: account_list, tnt_id: '-2079150908') }
    let!(:donation) do
      create(:donation, remote_id: 'ICWMY', amount: 50, donation_date: '2005-06-10'.to_date,
                        donor_account: donor_account, designation_account: designation)
    end

    context 'donation not linked to appeal' do
      it 'links donation' do
        described_class.new.perform(import.id)

        donation.reload
        expect(donation.appeal).to eq appeal
        expect(donation.appeal_amount).to eq 25
      end

      it 'created related pledge' do
        expect { described_class.new.perform(import.id) }.to change { Pledge.count }.by(1)
        pledge = Pledge.last
        expect(pledge.amount).to eq donation.reload.appeal_amount
        expect(pledge.appeal).to eq appeal
        expect(pledge.contact).to eq contact
        expect(pledge).to be_processed
      end

      it 'created related AppealContact' do
        expect { described_class.new.perform(import.id) }.to change { AppealContact.count }.by(1)
        appeal_contact = AppealContact.last
        expect(appeal_contact.appeal).to eq appeal
        expect(appeal_contact.contact).to eq contact
      end

      it 'links based on date/amount/donor' do
        donation.update(remote_id: 'DIFFERENT')

        described_class.new.perform(import.id)

        expect(donation.reload.appeal).to eq appeal
      end
    end

    context 'existing donation' do
      it 'increases the pledge' do
        appeal.contacts << contact
        create(:donation, amount: 20, appeal_amount: 20, donation_date: '2005-06-01'.to_date, appeal: appeal,
                          donor_account: donor_account, designation_account: designation)

        expect { described_class.new.perform(import.id) }.to change { Pledge.count }.by(0)
        pledge = Pledge.last
        expect(pledge.amount).to eq 45
      end
    end

    context 'donation has been linked to another appeal' do
      it "doesn't link donation to appeal" do
        donation.update(appeal: create(:appeal, account_list: account_list))

        expect { described_class.new.perform(import.id) }.to_not change { donation.reload.appeal_id }
      end
    end
  end
end
