class Contact::Filter::NoAppeals < Contact::Filter::Base
  def execute_query(scope, filters)
    scope.where(no_appeals: (filters[:no_appeals].to_s == 'true'))
  end
end
