class TagValidator
  def validate(tag_name)
    errors = {}
    errors[:name] = ["can't be blank"] if tag_name.blank?
    return false if errors.empty?
    errors
  end
end
