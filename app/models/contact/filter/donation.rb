class Contact::Filter::Donation < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, account_list)
      contacts = contacts.includes(donor_accounts: [:donations]).references(donor_accounts: [:donations])
      contacts = contacts.where(donations: { id: nil }) if filters[:donation].include?('none')
      contacts = contacts.where.not(donations: { id: nil }) if filters[:donation].include?('one')
      contacts = contacts.where(donations: { id: first_donation_for_each_donor_account(account_list).pluck(:id) }) if filters[:donation].include?('first')
      contacts = contacts.where(donations: { id: last_donation_for_each_donor_account(account_list).pluck(:id) }) if filters[:donation].include?('last')
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

    def custom_options(_account_list)
      [{ name: _('No Gifts'), id: 'none' },
       { name: _('One or More Gifts'), id: 'one' },
       { name: _('First Gift'), id: 'first' },
       { name: _('Last Gift'), id: 'last' }]
    end

    private

    def valid_filters?(filters)
      super && filters[:donation].is_a?(Array)
    end

    # The first and last donation queries use the SQL aggregation MIN/MAX functions to find donation_date grouped by the donor_account_id.
    def last_donation_for_each_donor_account(account_list)
      account_list.donations.joins(
        <<~JOIN
          INNER JOIN (SELECT donor_account_id, MAX(donation_date) AS max_donation_date
                      FROM donations
                      WHERE #{account_list.donations.where_values.collect(&:to_sql).join(' AND ')}
                      GROUP BY donor_account_id) grouped_donations
          ON donations.donor_account_id = grouped_donations.donor_account_id
          AND donations.donation_date = grouped_donations.max_donation_date
        JOIN
      )
    end

    def first_donation_for_each_donor_account(account_list)
      account_list.donations.joins(
        <<~JOIN
          INNER JOIN (SELECT donor_account_id, MIN(donation_date) AS min_donation_date
                      FROM donations
                      WHERE #{account_list.donations.where_values.collect(&:to_sql).join(' AND ')}
                      GROUP BY donor_account_id) grouped_donations
          ON donations.donor_account_id = grouped_donations.donor_account_id
          AND donations.donation_date = grouped_donations.min_donation_date
        JOIN
      )
    end
  end
end
