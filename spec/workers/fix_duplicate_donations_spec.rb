require 'rails_helper'

describe FixDuplicateDonations do
  let(:account_list) { create(:account_list) }
  let(:designation_profile) { create(:designation_profile, account_list: account_list) }
  let(:tnt_donor_account) { create(:donor_account, account_number: '1111111') }
  let(:remote_donor_account) { create(:donor_account, account_number: '2222222') }
  let(:contact) { create(:contact, account_list: account_list) }

  let(:designation_account_good) do
    create(:designation_account, account_lists: [account_list])
  end
  let(:designation_account_bad) do
    create(:designation_account, account_lists: [account_list],
                                 designation_number: nil)
  end
  let(:appeal) { create(:appeal, account_list: account_list) }

  let!(:donation) do
    create(:donation, donation_date: 1.day.ago,
                      designation_account: designation_account_good,
                      donor_account: remote_donor_account,
                      appeal: appeal,
                      remote_id: '1-abc-001')
  end

  let!(:donation_dup) do
    create(:donation, donation_date: 1.day.ago,
                      designation_account: designation_account_bad,
                      donor_account: tnt_donor_account,
                      created_at: 2.years.ago,
                      appeal: appeal,
                      remote_id: '1-abc-010')
  end

  before do
    contact.donor_accounts << tnt_donor_account
    contact.donor_accounts << remote_donor_account

    account_list.users << designation_profile.user

    designation_account_good.designation_profiles << designation_profile
    designation_account_bad.designation_profiles << designation_profile
  end

  def perform_worker
    FixDuplicateDonations.new.perform(designation_account_bad.id)
  end

  def donation_count
    account_list.donations.count
  end

  context 'a duplicate exists' do
    it 'removes the duplicate donation' do
      expect { perform_worker }.to change { donation_count }.from(2).to(1)
    end

    it 'saves the donation to a designation_account' do
      expect { perform_worker }.to change { donation_dup.reload.designation_account_id }
    end

    it 'saves the old designation_account_id on the memo' do
      perform_worker

      expect(donation_dup.reload.memo).to include designation_account_bad.id.to_s
    end

    it 'saves the old account_list_id on the memo' do
      perform_worker

      expect(donation_dup.reload.memo).to include account_list.id.to_s
    end

    it 'saves the old donor account on the memo' do
      perform_worker

      expect(donation_dup.reload.memo).to include tnt_donor_account.name
      expect(donation_dup.memo).to include tnt_donor_account.account_number
    end

    it 'destroys empty DonorAccount' do
      perform_worker

      expect(DonorAccount.find_by(id: tnt_donor_account.id)).to be nil
    end

    it 'transfers appeal_id and appeal amount' do
      donation.update(appeal: nil, appeal_amount: nil)
      donation_dup.update(appeal_amount: donation.amount / 2)

      perform_worker

      expect(donation.reload.attributes).to include('appeal_id' => appeal.id,
                                                    'appeal_amount' => donation_dup.appeal_amount)
    end

    it "doesn't match if tendered_currency doesn't match" do
      donation_dup.update(tendered_currency: 'USD')

      expect { perform_worker }.not_to change { donation_count }
    end

    it "doesn't match if dup donations was associated with different appeal" do
      donation_dup.update(appeal: create(:appeal, account_list: account_list))

      expect { perform_worker }.not_to change { donation_count }
    end
  end

  context 'no duplicate exists' do
    it "doesn't change donation count" do
      donation_dup.destroy

      expect { perform_worker }.not_to change { donation_count }
    end
  end
end
