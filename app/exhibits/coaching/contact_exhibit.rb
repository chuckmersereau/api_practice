class Coaching::ContactExhibit < PersonExhibit
  def self.applicable_to?(object)
    object.class.name == 'Contact'
  end
end
