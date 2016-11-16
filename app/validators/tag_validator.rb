class TagValidator
  def validate(tag_name)
    errors = {}
    errors[:name] = ["Can't be blank"] if tag_name.blank?
    return false if errors.empty?
    errors
  end
end
