# We define stopped giving any contact with at least 3 gifts that gave his last donation within the time range.
class Contact::Filter::StoppedGivingRange < Contact::Filter::Base
  # If a donor stopped giving after 3 gifts we can assume that he actually gave regularly and then stopped
  PRIOR_NUMBER_OF_GIFTS = 3

  def execute_query(scope, filters)
    @contacts_that_have_stopped_giving = scope.where(last_donation_date: filters[:stopped_giving_range])

    @last_ten_months = (filters[:stopped_giving_range].last - 10.months)..filters[:stopped_giving_range].last
    @contacts_that_have_stopped_giving.where(id: ids_of_contacts_that_stopped_giving_and_have_more_than_three_donations)
  end

  def valid_filters?(filters)
    super && date_range?(filters[:stopped_giving_range]) && filters[:stopped_giving_range].last <= valid_end_date
  end

  private

  def valid_end_date
    1.month.ago + 1.day
  end

  def ids_of_contacts_that_stopped_giving_and_have_more_than_three_donations
    DonorAccount.joins({ contact_donor_accounts: :contact }, :donations)
                .where(contact_donor_accounts: { contact: @contacts_that_have_stopped_giving },
                       donations: { donation_date: @last_ten_months })
                .group('contacts.id')
                .having('COUNT(*) >= ?', PRIOR_NUMBER_OF_GIFTS).pluck('contacts.id')
  end
end
