class Appeal < ActiveRecord::Base
  belongs_to :account_list
  has_many :appeal_contacts
  has_many :contacts, through: :appeal_contacts
  has_many :donations

  validates :account_list_id, presence: true

  default_scope { order(created_at: :desc) }

  PERMITTED_ATTRIBUTES = [:id, :name, :amount, :description, :end_date, :account_list_id].freeze

  def add_and_remove_contacts(account_list, contact_ids)
    contact_ids ||= []

    valid_contact_ids = account_list.contacts.pluck(:id) & contact_ids
    new_contact_ids = valid_contact_ids - contacts.pluck(:id)
    new_contact_ids.each do |contact_id|
      return false unless AppealContact.new(appeal_id: id, contact_id: contact_id).save
    end

    contact_ids_to_remove = contacts.pluck(:id) - contact_ids
    contact_ids_to_remove.each do |contact_id|
      contacts.delete(contact_id)
    end
  end

  def add_contacts_by_opts(statuses, tags, excludes)
    bulk_add_contacts(contacts_by_opts(statuses, tags, excludes))
  end

  def bulk_add_contacts(contacts_to_add)
    appeal_contact_ids = contacts.pluck(:id).to_set
    contacts_to_add = contacts_to_add.uniq.reject { |c| appeal_contact_ids.include?(c.id) }
    AppealContact.import(contacts_to_add.map { |c| AppealContact.new(contact: c, appeal: self) })
  end

  def contacts_by_opts(statuses, tags, excludes)
    excludes_scopes(account_list.contacts
      .joins("LEFT JOIN taggings ON taggings.taggable_type = 'Contact' AND taggings.taggable_id = contacts.id")
      .joins('LEFT JOIN tags ON tags.id = taggings.tag_id')
      .distinct
      .where(statuses_and_tags_where(statuses, tags)), excludes)
  end

  def statuses_and_tags_where(statuses, tags)
    if statuses.nil? || statuses.empty?
      tags.nil? || tags.empty? ? '1=0' : "tags.name IN (#{quote_sql_list(tags)})"
    elsif tags.nil? || tags.empty?
      "contacts.status IN (#{quote_sql_list(statuses)})"
    else
      "contacts.status IN (#{quote_sql_list(statuses)}) OR tags.name IN (#{quote_sql_list(tags)})"
    end
  end

  def quote_sql_list(list)
    list.map { |item| ActiveRecord::Base.connection.quote(item) }.join(',')
  end

  def excludes_scopes(contacts, excludes)
    excludes ||= {}
    contacts = contacts.where("no_appeals is null OR no_appeals = 'f'") if excludes[:doNotAskAppeals]
    contacts = no_joined_recently(contacts, 3) if excludes[:joinedTeam3months]
    contacts = no_above_pledge_recently(contacts, 3) if excludes[:specialGift3months]
    contacts = no_stopped_giving_recently(contacts, 2) if excludes[:stoppedGiving2months]
    contacts = no_increased_recently(contacts, 3) if excludes[:increasedGiving3months]
    contacts
  end

  def no_joined_recently(contacts, within_months)
    contacts.where.not('pledge_amount is not null AND pledge_amount > 0 AND '\
                       'contacts.first_donation_date is not null AND '\
                       'contacts.first_donation_date >= ?',
                       within_months.months.ago)
  end

  def no_above_pledge_recently(contacts, prev_full_months)
    start_of_month = Date.today.beginning_of_month
    start_of_prev_month = (Date.today << prev_full_months).beginning_of_month

    # I wrote this in SQL because we populate the appeal contacts for the user
    # as part of the wizard (not in the background), so it needs to be fast.
    above_pledge_contacts_ids_sql = "
      SELECT contacts.id
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
        WHERE contacts.account_list_id = :account_list_id AND donations.donation_date >= :start_of_prev_month
          AND donations.designation_account_id IN (
            SELECT designation_account_id FROM account_list_entries WHERE account_list_id = :account_list_id
          )
      ) contact_donations
      GROUP BY contact_id, pledge_amount, pledge_frequency
      HAVING
        SUM(donation_amount)
          / ((CASE WHEN contacts.last_donation_date >= :start_of_month THEN 1 ELSE 0 END) + :prev_full_months)
        > coalesce(pledge_amount, 0.0) / coalesce(pledge_frequency, 1.0)"

    contacts.where("contacts.id NOT IN (#{above_pledge_contacts_ids_sql})",
                   account_list_id: account_list.id, start_of_month: start_of_month,
                   start_of_prev_month: start_of_prev_month, prev_full_months: prev_full_months)
  end

  # We define e.g. "stopped giving in the past 2 months" as no pledge set current, no gifts in the previous
  # 2 full months, and at least 3 gifts in the prior 10 months.
  def no_stopped_giving_recently(contacts, prev_full_months = 2, prior_months = 10, prior_num_gifts = 3)
    prior_window_end = Date.today << prev_full_months
    prior_window_start = prior_window_end << prior_months

    former_givers_sql = "
      SELECT contacts.id
      FROM contacts
      INNER JOIN contact_donor_accounts cda on cda.contact_id = contacts.id
      INNER JOIN donor_accounts da on da.id = cda.donor_account_id
      INNER JOIN donations ON donations.donor_account_id = da.id
      WHERE contacts.account_list_id = :account_list_id
        AND (contacts.pledge_amount is null OR contacts.pledge_amount = 0)
        AND contacts.last_donation_date <= :prior_window_end
        AND donations.donation_date >= :prior_window_start
        AND donations.donation_date <= :prior_window_end
        AND donations.designation_account_id IN (
          SELECT designation_account_id FROM account_list_entries WHERE account_list_id = :account_list_id
        )
      GROUP BY contacts.id
      HAVING COUNT(*) >= :prior_num_gifts"

    contacts.where("contacts.id NOT IN (#{former_givers_sql})",
                   account_list_id: account_list.id, prior_num_gifts: prior_num_gifts,
                   prior_window_start: prior_window_start, prior_window_end: prior_window_end)
  end

  def no_increased_recently(contacts, prev_full_months = 3)
    increased_recently_ids = contacts.scoping do
      account_list.contacts
                  .where('pledge_amount is not null AND pledge_amount > 0 AND pledge_frequency <= 4')
                  .where('last_donation_date >= ?', (Date.today.prev_month << prev_full_months).beginning_of_month)
                  .to_a.select { |contact| increased_recently?(contact, prev_full_months) }.map(&:id)
    end

    return contacts if increased_recently_ids.empty?

    contacts.where("contacts.id NOT IN (#{quote_sql_list(increased_recently_ids)})")
  end

  def increased_recently?(contact, prev_full_months, max_prior_months = 12)
    monthly_totals = monthly_donation_totals(contact, prev_full_months + max_prior_months)
    return false if monthly_totals.size < 2

    calc_all_elapsed_months(monthly_totals, contact.pledge_frequency)

    # If they gave this month, make the cut off 3 months ago, if they didn't give this month yet, make it
    # 4 months ago so we are capturing 3 complete months of giving.
    months_ago_cutoff = prev_full_months + (month_diff(contact.last_donation_date, Date.today) == 0 ? 0 : 1)

    net_increase = 0
    last_total = monthly_totals.pop
    monthly_totals.reverse_each do |prev_total|
      break if month_diff(Date.today, last_total[:date]) >= months_ago_cutoff
      net_increase += last_total[:total] / last_total[:elapsed_months] - prev_total[:total] / prev_total[:elapsed_months]
      last_total = prev_total
    end

    net_increase > 0
  end

  def monthly_donation_totals(contact, months_ago)
    contact.donations
           .select("SUM(amount) total, date_part('year', donation_date) as year, date_part('month', donation_date) as month")
           .where('donation_date > ?', months_ago.months.ago.beginning_of_month)
           .group("date_part('year', donation_date), date_part('month', donation_date)").reorder('2, 3')
           .to_a.map { |mt| { total: mt.total, date: Date.new(mt.year, mt.month, 1) } }
  end

  def calc_all_elapsed_months(monthly_totals, pledge_frequency)
    older_total = monthly_totals.first
    older_total[:elapsed_months] = pledge_frequency # Use pledge frequency for oldest donation
    monthly_totals.each_with_index do |total, i|
      next if i == 0
      total[:elapsed_months] = month_diff(total[:date], older_total[:date])
      older_total = total
    end

    # For the most recent gift, add the months late to the elapsed time to handle cases where a donor
    # gives a larger gift early, i.e. $5, $5, $10, $0 is not an increase and a missed month, but the $10
    # is probably their gift for the past two months.
    months_late = [0, month_diff(Date.today, older_total[:date]) - pledge_frequency].max
    older_total[:elapsed_months] += months_late
  end

  def month_diff(date2, date1)
    (date2.year - date1.year) * 12 + date2.month - date1.month
  end
end
