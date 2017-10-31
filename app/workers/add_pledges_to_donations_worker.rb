class AddPledgesToDonationsWorker
  include Sidekiq::Worker

  def perform
    donations_without_pledges.find_each do |donation|
      appeal = donation.appeal
      next unless appeal
      account_list = appeal.account_list
      next unless account_list
      contact = donation.donor_account.contacts.where(account_list: account_list).first
      next unless contact
      create_pledge(account_list, donation, contact, appeal)
    end
  end

  private

  def donations_without_pledges
    Donation.where
            .not(appeal: nil)
            .includes(:pledge_donations)
            .where(pledge_donations: { id: nil })
  end

  def create_pledge(account_list, donation, contact, appeal)
    account_list.pledges.create(
      amount: donation.appeal_amount.to_i.positive? ? donation.appeal_amount : donation.amount,
      appeal: appeal,
      contact: contact,
      donations: [donation],
      expected_date: donation.donation_date
    )
  end
end
