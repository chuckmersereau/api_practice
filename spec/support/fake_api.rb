class FakeApi
  def initialize(*_args)
  end

  def self.requires_username_and_password?
    true
  end

  def requires_username_and_password?
    self.class.requires_username_and_password?
  end

  def validate_username_and_password(*_args)
    true
  end

  def profiles
    []
  end

  def profiles_with_designation_numbers
    []
  end

  def method_missing(*_args, &_block)
    true
  end

  def import_all(args)
  end
end
