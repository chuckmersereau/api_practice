class Contact::Filter::Donation < Contact::Filter::Base
  attr_accessor :contacts, :filters

  def execute_query(query_contacts, query_filters)
    self.contacts = query_contacts.includes(donor_accounts: [:donations])
    self.filters = query_filters
    filter_contacts
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

  def filters=(filters)
    @filters = parse_list(filters[:donation])
  end

  def filter_contacts
    no_gifts
    one_or_more_gifts
    first_gift
    last_gift
    contacts
  end

  def no_gifts
    return unless filters.include?('none')
    self.contacts = contacts.where.not(id: contact_ids_with_donation_to_account_lists)
  end

  def one_or_more_gifts
    return unless filters.include?('one')
    self.contacts = contacts.where(id: contact_ids_with_donation_to_account_lists)
  end

  def first_gift
    return unless filters.include?('first')
    self.contacts = contacts.where(donations: { id: first_donation_ids_for_each_donor_account })
  end

  def last_gift
    return unless filters.include?('last')
    self.contacts = contacts.where(donations: { id: last_donation_ids_for_each_donor_account })
  end

  def contact_ids_with_donation_to_account_lists
    @contact_ids_with_donation_to_account_lists ||=
      Donation.unscoped
              .where(account_lists_donations_as_sql_condition)
              .joins(donor_account: [:contacts])
              .where(contacts: { account_list_id: account_lists })
              .distinct
              .pluck('"contacts"."id"')
  end

  # The last donation queries use the SQL aggregation MAX functions to
  # find donation_date grouped by the donor_account_id.
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

  # The first donation queries use the SQL aggregation MIN functions to
  # find donation_date grouped by the donor_account_id.
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
