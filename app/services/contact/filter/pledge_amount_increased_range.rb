class Contact::Filter::PledgeAmountIncreasedRange < Contact::Filter::Base
  attr_accessor :scope, :filters

  def execute_query(scope, filters)
    @scope = scope
    @filters = filters

    scope.where(id: contact_ids_where_pledge_amount_changed)
  end

  def valid_filters?(filters)
    date_range?(filters[:pledge_amount_increased_range])
  end

  private

  def contact_ids_where_pledge_amount_changed
    log_monthly_amount = 'MAX(coalesce(partner_status_logs.pledge_amount, 0.0) / coalesce(partner_status_logs.pledge_frequency, 1.0))'
    contact_monthly_amount = 'coalesce(contacts.pledge_amount, 0.0) / coalesce(contacts.pledge_frequency, 1.0)'
    PartnerStatusLog.where(contact_id: scope.pluck(:id))
                    .where(recorded_on: filters[:pledge_amount_increased_range])
                    .joins(:contact)
                    .group('contact_id, contacts.pledge_amount, contacts.pledge_frequency')
                    .having("#{log_monthly_amount} < #{contact_monthly_amount}")
                    .pluck(:contact_id)
  end
end
