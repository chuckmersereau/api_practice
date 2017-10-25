class AccountList::PledgeMatcher
  attr_accessor :donation

  delegate :appeal, to: :donation

  def initialize(donation)
    @donation = donation
  end

  def needs_pledge?
    appeal.present? && contact.present? && donation.pledges.empty?
  end

  def pledge
    @pledge ||= existing_pledge || create_pledge if needs_pledge?
  end

  private

  def existing_pledge
    pledge_scope.find_by(contact_id: contact)
  end

  def pledge_scope
    appeal.pledges
  end

  def contact
    @contact ||=
      contact_scope.find_by(
        contact_donor_accounts: { donor_account: donation.donor_account }
      )
  end

  def contact_scope
    appeal.contacts.joins(:contact_donor_accounts)
  end

  def create_pledge
    Pledge.create(
      amount: donation.safe_appeal_amount,
      expected_date: donation.donation_date,
      account_list: appeal.account_list,
      contact: contact,
      amount_currency: donation.currency,
      appeal: appeal
    )
  end
end
