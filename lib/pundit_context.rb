class PunditContext
  attr_reader :user
  attr_reader :extra_context

  def initialize(user, extra_context = nil)
    @user = validate_user(user)
    @extra_context = validate_extra_context(extra_context)
  end

  def method_missing(method_name, *args, &block)
    if extra_context_item_keys.include?(method_name)
      extra_context.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    extra_context_item_keys.include?(method_name) || super
  end

  private

  def extra_context_item_keys
    @context_item_keys ||= extra_context.to_h.keys
  end

  def validate_user(user_candidate)
    return user_candidate if user_candidate.class.name == 'User'

    raise ArgumentError, 'expected an instance of User'
  end

  def validate_extra_context(context_candidate)
    context_candidate ||= {}
    return OpenStruct.new(context_candidate) if context_candidate.is_a?(Hash)

    raise ArgumentError, 'Extra context (the 2nd param) must be a hash'
  end
end
