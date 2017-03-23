class UploadExtensionValidator < ActiveModel::EachValidator
  def initialize(options)
    options[:message] ||= 'You must specify a file with extension .#{options[:extension]}'
    super
  end

  def validate_each(record, attribute, value)
    return if value.present? && File.extname(value&.path).to_s.downcase == ".#{options[:extension]}"
    record.errors[attribute] << _(options[:message])
  end
end
