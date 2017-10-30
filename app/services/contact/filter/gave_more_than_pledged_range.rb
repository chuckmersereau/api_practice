## I kept things on a monthly basis here since the only way to make sure that we get all contacts that have
# given more than pledged is to look at the entire month.
class Contact::Filter::GaveMoreThanPledgedRange < Contact::Filter::Base
  def execute_query(contacts, filters)
    beginning_of_start_month = filters[:gave_more_than_pledged_range].first.beginning_of_month
    beginning_of_end_month = fetch_beginning_of_end_month_from_date_range(filters[:gave_more_than_pledged_range])
    number_of_months = (beginning_of_end_month.year * 12 + beginning_of_end_month.month) -
                       (beginning_of_start_month.year * 12 + beginning_of_start_month.month)

    contacts.where("contacts.id IN (#{above_pledge_contacts_ids_sql})",
                   account_list_id: account_lists.first.id,
                   beginning_of_start_month: beginning_of_start_month,
                   beginning_of_end_month: beginning_of_end_month,
                   number_of_months: number_of_months)
  end

  def valid_filters?(filters)
    date_range?(filters[:gave_more_than_pledged_range])
  end

  private

  def above_pledge_contacts_ids_sql
    'SELECT contact_donations.contact_id
    FROM
    (
      SELECT DISTINCT contacts.id as contact_id,
        contacts.last_donation_date, contacts.pledge_amount,
        contacts.pledge_frequency, donations.id as donation_id,
        donations.amount as donation_amount
      FROM contacts
      INNER JOIN contact_donor_accounts cda on cda.contact_id = contacts.id
      INNER JOIN donor_accounts da on da.id = cda.donor_account_id
      INNER JOIN donations ON donations.donor_account_id = da.id
      WHERE contacts.account_list_id = :account_list_id AND donations.donation_date >= :beginning_of_start_month
        AND donations.designation_account_id IN (
          SELECT designation_account_id FROM account_list_entries WHERE account_list_id = :account_list_id
        )
    ) contact_donations
    GROUP BY contact_id, pledge_amount, pledge_frequency, last_donation_date
    HAVING
      SUM(donation_amount)
        / ((CASE WHEN contact_donations.last_donation_date >= :beginning_of_end_month THEN 1 ELSE 0 END) + :number_of_months)
      > coalesce(pledge_amount, 0.0) / coalesce(pledge_frequency, 1.0)'
  end
end
