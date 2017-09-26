class Person::Filter::Deceased < Person::Filter::Base
  def execute_query(people, filters)
    people.where(deceased: filters[:deceased]&.to_s == 'true')
  end
end
