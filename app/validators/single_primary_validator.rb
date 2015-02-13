class SinglePrimaryValidator < ActiveModel::EachValidator
  attr_reader :record, :attribute, :value

  def initialize(options)
    options[:primary_field] ||= :primary
    options[:message] ||= 'must have one and only one set as valid and primary'
    super
  end

  def validate_each(record, attribute, value)
    @record, @attribute, @value = record, attribute, value

    add_error unless valid?
  end

  private

  def valid?
    return false if value.select(&:historic).any?(&options[:primary_field])
    non_historic = value.reject(&:historic)
    non_historic.empty? || non_historic.count(&options[:primary_field]) == 1
  end

  def add_error
    if message = options[:message]
      record.errors[attribute] << message
    else
      record.errors.add(attribute, :invalid)
    end
  end
end
