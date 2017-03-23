class ClassValidator < ActiveModel::EachValidator
  def initialize(options)
    raise(ArgumentError, 'You must supply a validation value for is_a') unless options[:is_a].present?
    options[:message] ||= "should be a #{json_type(options[:is_a])}"
    options[:allow_nil] ||= false
    super
  end

  def validate_each(record, attribute, value)
    return if options[:allow_nil] && value.nil?
    return if value.is_a?(options[:is_a])
    record.errors[attribute] << options[:message]
  end

  private

  def json_type(klass)
    {
      'Hash' => 'Object'
    }[klass.to_s] || klass.to_s
  end
end
