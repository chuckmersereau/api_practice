class PhoneNumberValidator < ActiveModel::EachValidator
  attr_reader :record, :attribute, :value

  def validate_each(record, attribute, value)
    @record = record
    @attribute = attribute
    @value = value

    add_error unless valid?
  end

  private

  def valid?
    Phonelib.parse(value).valid?
  end

  def add_error
    if message = options[:message]
      record.errors[attribute] << message
    else
      record.errors.add(attribute, :invalid)
    end
  end
end
