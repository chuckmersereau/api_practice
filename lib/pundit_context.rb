class PunditContext
  attr_reader :user

  def initialize(user, extra_context_object)
    raise ArgumentError, 'expected an instance of User' unless user.is_a? User
    @user = user
    define_singleton_method(extra_context_object.class.to_s.underscore) { extra_context_object }
  end
end
