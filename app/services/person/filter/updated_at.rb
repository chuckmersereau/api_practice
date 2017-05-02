class Person::Filter::UpdatedAt < Person::Filter::Base
  def execute_query(people, filters)
    people.where(updated_at: filters[:updated_at])
  end
end
