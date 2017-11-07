class FakeApi
  def initialize(*_args)
  end

  def self.requires_credentials?
    true
  end

  def requires_credentials?
    self.class.requires_credentials?
  end

  def validate_credentials(*_args)
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
