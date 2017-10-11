class Coaching::PersonSerializer < PersonSerializer
  def person_exhibit
    @exhibit ||= Coaching::PersonExhibit.new(object, nil)
  end
end
