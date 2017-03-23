class FileSizeValidator < ActiveModel::EachValidator
  def initialize(options)
    raise(ArgumentError, 'You must supply a validation value for less_than (in bytes)') unless options[:less_than]&.is_a?(Integer)
    options[:message] ||= "File size must be less than #{options[:less_than]} bytes"
    super
  end

  def validate_each(record, attribute, value)
    return unless value&.size
    return if value.size <= options[:less_than]
    record.errors[attribute] << options[:message]
  end
end
