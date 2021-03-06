class Contact::Filter::StartedGivingRange < Contact::Filter::Base
  def execute_query(scope, filters)
    scope.where('pledge_amount is not null AND pledge_amount > 0')
         .where(first_donation_date: filters[:started_giving_range])
  end

  def valid_filters?(filters)
    date_range?(filters[:started_giving_range])
  end
end
