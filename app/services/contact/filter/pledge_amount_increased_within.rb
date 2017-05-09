class Contact::Filter::PledgeAmountIncreasedWithin < Contact::Filter::Base
  attr_accessor :scope, :filters

  def execute_query(scope, filters)
    @scope = scope
    @filters = filters

    ids_of_contacts_with_pledge_amount_increase.compact
    scope.where(id: ids_of_contacts_with_pledge_amount_increase)
  end

  private

  def ids_of_contacts_with_pledge_amount_increase
    groups_of_partner_status_logs_associated_to_the_same_contact.map do |partner_status_logs|
      ordered_status_logs = partner_status_logs.second.sort_by(&:recorded_on)

      initial_amount_per_month = amount_per_month_from_status_log(ordered_status_logs.first)
      final_amount_per_month = amount_per_month_from_status_log(ordered_status_logs.last)

      partner_status_logs.first if final_amount_per_month > initial_amount_per_month
    end.compact
  end

  def groups_of_partner_status_logs_associated_to_the_same_contact
    PartnerStatusLog.where(contact_id: contact_ids_where_pledge_amount_changed).group_by(&:contact_id)
  end

  def contact_ids_where_pledge_amount_changed
    PartnerStatusLog.where(contact: scope)
                    .where(recorded_on: filters[:pledge_amount_increased_within])
                    .group(:contact_id)
                    .having('MAX(coalesce(pledge_amount, 0.0) / coalesce(pledge_frequency, 1.0)) > '\
                            'AVG(coalesce(pledge_amount, 0.0) / coalesce(pledge_frequency, 1.0))').pluck(:contact_id)
  end

  def amount_per_month_from_status_log(status_log)
    (status_log.pledge_amount || 0.0) / (status_log.pledge_frequency || 1.0)
  end
end
