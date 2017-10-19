class Coaching::PersonExhibit < PersonExhibit
  def self.applicable_to?(object)
    object.class.name == 'User'
  end
end
