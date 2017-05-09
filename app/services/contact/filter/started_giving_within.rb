class Contact::Filter::StartedGivingWithin < Contact::Filter::Base
  def execute_query(scope, filters)
    scope.where('pledge_amount is not null AND pledge_amount > 0')
         .where(first_donation_date: filters[:started_giving_within])
  end
end
