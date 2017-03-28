class AccountList::PledgeMatcher
  attr_accessor :pledge_scope, :donation

  def initialize(pledge_scope:, donation:)
    @pledge_scope = pledge_scope
    @donation = donation
  end

  def match
    pledges_on_donation_day.where(contact_id: contact_scope)
                           .where(amount: donation.amount)
  end

  private

  def contact_scope
    Contact.joins(:contact_donor_accounts)
           .where(contact_donor_accounts: { donor_account_id: donation.donor_account })
  end

  def pledges_on_donation_day
    pledge_scope.where('expected_date BETWEEN ? AND ?',
                       donation.donation_date.beginning_of_day,
                       donation.donation_date.end_of_day)
  end
end
