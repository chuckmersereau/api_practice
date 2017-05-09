class UploadExtensionValidator < ActiveModel::EachValidator
  def initialize(options)
    options[:message] ||= 'You must specify a file with extension .#{options[:extension]}'
    super
  end

  def validate_each(record, attribute, value)
    file_extension = File.extname(value&.path || '').delete('.').to_s.downcase
    extensions = Array.wrap(options[:extension])
    return if value.present? && extensions.include?(file_extension)
    record.errors[attribute] << _(options[:message])
  end
end
