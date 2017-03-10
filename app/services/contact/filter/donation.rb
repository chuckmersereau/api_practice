class Contact::Filter::Donation < Contact::Filter::Base
  def execute_query(contacts, filters)
    donation_filters = filters[:donation].split(',').map(&:strip)
    contacts = contacts.includes(donor_accounts: [:donations]).references(donor_accounts: [:donations])
    contacts = contacts.where(donations: { id: nil }) if donation_filters.include?('none')
    contacts = contacts.where.not(donations: { id: nil }) if donation_filters.include?('one')
    contacts = contacts.where(donations: { id: first_donation_ids_for_each_donor_account }) if donation_filters.include?('first')
    contacts = contacts.where(donations: { id: last_donation_ids_for_each_donor_account }) if donation_filters.include?('last')
    contacts
  end

  def title
    _('Gift Options')
  end

  def parent
    _('Gift Details')
  end

  def type
    'multiselect'
  end

  def custom_options
    [{ name: _('No Gifts'), id: 'none' },
     { name: _('One or More Gifts'), id: 'one' },
     { name: _('First Gift'), id: 'first' },
     { name: _('Last Gift'), id: 'last' }]
  end

  private

  # The first and last donation queries use the SQL aggregation MIN/MAX functions to find donation_date grouped by the donor_account_id.
  def last_donation_ids_for_each_donor_account
    Donation.where(account_lists_donations_as_sql_condition).joins(
      <<~JOIN
        INNER JOIN (SELECT donor_account_id, MAX(donation_date) AS max_donation_date
                    FROM donations
                    WHERE #{account_lists_donations_as_sql_condition}
                    GROUP BY donor_account_id) grouped_donations
        ON donations.donor_account_id = grouped_donations.donor_account_id
        AND donations.donation_date = grouped_donations.max_donation_date
      JOIN
    ).pluck(:id)
  end

  def first_donation_ids_for_each_donor_account
    Donation.where(account_lists_donations_as_sql_condition).joins(
      <<~JOIN
        INNER JOIN (SELECT donor_account_id, MIN(donation_date) AS min_donation_date
                    FROM donations
                    WHERE #{account_lists_donations_as_sql_condition}
                    GROUP BY donor_account_id) grouped_donations
        ON donations.donor_account_id = grouped_donations.donor_account_id
        AND donations.donation_date = grouped_donations.min_donation_date
      JOIN
    ).pluck(:id)
  end

  # Build the SQL condition needed to return all donations for all account_lists.
  def account_lists_donations_as_sql_condition
    account_lists_donations_sql = account_lists.collect do |account_list|
      account_list.donations.where_values.collect(&:to_sql).join(' AND ')
    end
    account_lists_donations_sql.collect { |sql| "(#{sql})" }.join(' OR ')
  end
end
