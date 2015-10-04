class UploadExtensionValidator < ActiveModel::EachValidator
  def initialize(options)
    options[:message] ||= "You must specify a file with extension .#{options[:extension]}"
    super
  end

  def validate_each(record, _attribute, value)
    unless value.present? && File.extname(value.filename).to_s.downcase == ".#{options[:extension]}"
      record.errors[:base] << _(options[:message])
    end
  end
end
