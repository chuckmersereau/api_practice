# We define stopped giving any contact with at least 3
# gifts that gave his last donation within the time range.
class Contact::Filter::StoppedGivingRange < Contact::Filter::Base
  # If a donor stopped giving after 3 gifts we can assume
  # that he actually gave regularly and then stopped
  PRIOR_NUMBER_OF_GIFTS = 3

  def execute_query(scope, filters)
    @contacts_that_have_stopped_giving = scope.where(last_donation_date: filters[:stopped_giving_range])

    end_date = filters[:stopped_giving_range].last
    @last_ten_months = (end_date - 10.months)..end_date
    @contacts_that_have_stopped_giving.where(id: stopped_giving_and_many_donations_contact_ids)
  end

  def valid_filters?(filters)
    super &&
      date_range?(filters[:stopped_giving_range]) &&
      filters[:stopped_giving_range].last <= valid_end_date
  end

  private

  def valid_end_date
    1.month.ago + 1.day
  end

  def stopped_giving_and_many_donations_contact_ids
    conditions = {
      contact_donor_accounts: { contact_id: @contacts_that_have_stopped_giving.pluck(:id) },
      donations: { donation_date: @last_ten_months }
    }
    DonorAccount.joins({ contact_donor_accounts: :contact }, :donations)
                .where(conditions)
                .group('contacts.id')
                .having('COUNT(*) >= ?', PRIOR_NUMBER_OF_GIFTS).pluck('contacts.id')
  end
end
