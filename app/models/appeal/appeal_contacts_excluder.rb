class Appeal::AppealContactsExcluder
  include ActiveModel::Model
  include ActiveRecord::Sanitization::ClassMethods

  attr_accessor :appeal

  def excludes_scopes(contacts, excludes)
    return contacts unless excludes.is_a? Hash

    @exclusions = {}
    Appeal::ExcludedAppealContact.where(appeal: appeal).delete_all
    @contacts = contacts

    do_not_ask if excludes[:doNotAskAppeals]
    no_joined_recently(3) if excludes[:joinedTeam3months]
    no_above_pledge_recently(3) if excludes[:specialGift3months]
    no_stopped_giving_recently(2) if excludes[:stoppedGiving2months]
    no_increased_recently(3) if excludes[:increasedGiving3months]

    contacts = contacts.where.not(id: @exclusions.keys) if @exclusions.any?

    save_exclusions
    contacts
  end

  private

  def account_list
    appeal.account_list
  end

  def do_not_ask
    ids = @contacts.where(no_appeals: true).pluck(:id)
    mark_excluded(ids, 'marked_do_not_ask')
  end

  def no_joined_recently(within_months)
    ids = @contacts.where('pledge_amount is not null AND pledge_amount > 0 AND '\
                         'contacts.first_donation_date is not null AND '\
                         'contacts.first_donation_date >= ?',
                         within_months.months.ago).pluck(:id)
    mark_excluded(ids, 'joined_recently')
  end

  def no_above_pledge_recently(prev_full_months)
    start_of_month = Date.today.beginning_of_month
    start_of_prev_month = (Date.today << prev_full_months).beginning_of_month

    # I wrote this in SQL because we populate the appeal contacts for the user
    # as part of the wizard (not in the background), so it needs to be fast.
    above_pledge_contacts_ids_sql = '
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
        > coalesce(pledge_amount, 0.0) / coalesce(pledge_frequency, 1.0)'

    ids = @contacts.where("contacts.id IN (#{above_pledge_contacts_ids_sql})",
                          account_list_id: account_list.id, start_of_month: start_of_month,
                          start_of_prev_month: start_of_prev_month, prev_full_months: prev_full_months).pluck(:id)
    mark_excluded(ids, 'special_gift')
  end

  # We define e.g. "stopped giving in the past 2 months" as no pledge set current, no gifts in the previous
  # 2 full months, and at least 3 gifts in the prior 10 months.
  def no_stopped_giving_recently(prev_full_months = 2, prior_months = 10, prior_num_gifts = 3)
    prior_window_end = Date.today << prev_full_months
    prior_window_start = prior_window_end << prior_months

    former_givers_sql = '
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
      HAVING COUNT(*) >= :prior_num_gifts'

    ids = @contacts.where("contacts.id IN (#{former_givers_sql})",
                          account_list_id: account_list.id, prior_num_gifts: prior_num_gifts,
                          prior_window_start: prior_window_start, prior_window_end: prior_window_end).pluck(:id)
    mark_excluded(ids, 'stopped_giving')
  end

  def no_increased_recently(prev_full_months = 3)
    increased_recently_ids = @contacts.scoping do
      account_list.contacts
                  .where('pledge_amount is not null AND pledge_amount > 0 AND pledge_frequency <= 4')
                  .where('last_donation_date >= ?', (Date.today.prev_month << prev_full_months).beginning_of_month)
                  .to_a.select { |contact| increased_recently?(contact, prev_full_months) }.map(&:id)
    end

    mark_excluded(increased_recently_ids, 'increased_recently')
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

  def quote_sql_list(list)
    list.map { |item| ActiveRecord::Base.connection.quote(item) }.join(',')
  end

  def mark_excluded(ids, reason)
    ids.each do |id|
      @exclusions[id] ||= []
      @exclusions[id].append reason
    end
  end

  def save_exclusions
    Appeal::ExcludedAppealContact.transaction do
      @exclusions.each do |id, reasons|
        Appeal::ExcludedAppealContact.create(contact_id: id, appeal: appeal, reasons: reasons)
      end
    end
  end
end
