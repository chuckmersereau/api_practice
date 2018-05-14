class Reports::PledgeHistoriesPeriod < ActiveModelSerializers::Model
  attr_accessor :account_list, :end_date, :start_date

  def pledged
    sum_partner_status_log_pledge_amounts(false) + sum_contact_pledge_amounts(false)
  end

  def received
    sum_partner_status_log_pledge_amounts(true) + sum_contact_pledge_amounts(true)
  end

  protected

  def sum_partner_status_log_pledge_amounts(pledge_received)
    partner_status_logs.where(pledge_received: pledge_received)
                       .to_a.sum(&method(:convert_pledge_amount))
  end

  def sum_contact_pledge_amounts(pledge_received)
    contacts = account_list.contacts
                           .where(pledge_received: pledge_received)
                           .where('created_at <= ?', end_date)
    contact_ids = partner_status_logs.pluck(:contact_id)
    contacts = contacts.where.not(id: contact_ids) unless contact_ids.empty?
    contacts.to_a.sum(&method(:convert_pledge_amount))
  end

  def convert_pledge_amount(object)
    CurrencyRate.convert_on_date(
      amount: (object.pledge_amount || 0) / (object.pledge_frequency || 1),
      from: object.pledge_currency,
      to: account_list.salary_currency_or_default,
      date: end_date
    )
  end

  def partner_status_logs
    @partner_status_logs ||=
      account_list.partner_status_logs
                  .select('DISTINCT ON ("partner_status_logs"."contact_id") "partner_status_logs".*')
                  .order(:contact_id, recorded_on: :asc)
                  .where('recorded_on > ?', end_date)
  end
end
