# We define stopped giving any contact with at least 3 gifts that gave his last donation within the time range.
class Contact::Filter::StoppedGivingWithin < Contact::Filter::Base
  PRIOR_NUMBER_OF_GIFTS = 3 # If a donor stopped giving after 3 gifts we can assume that he actually gave regularly and then stopped

  def execute_query(scope, filters)
    @contacts_that_have_stopped_giving = scope.where(last_donation_date: filters[:stopped_giving_within])

    @contacts_that_have_stopped_giving.where(id: ids_of_contacts_that_stopped_giving_and_have_more_than_three_donations)
  end

  def valid_filters?(filters)
    super && filters[:stopped_giving_within].last <= 1.month.ago
  end

  private

  def ids_of_contacts_that_stopped_giving_and_have_more_than_three_donations
    DonorAccount.joins({ contact_donor_accounts: :contact }, :donations)
                .where(contact_donor_accounts: { contact: @contacts_that_have_stopped_giving })
                .group('contacts.id')
                .having('COUNT(*) >= ?', PRIOR_NUMBER_OF_GIFTS).pluck('contacts.id')
  end
end
