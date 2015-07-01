class SinglePrimaryValidator < ActiveModel::EachValidator
  attr_reader :record, :attribute, :value

  def initialize(options)
    options[:primary_field] ||= :primary
    options[:message] ||= 'must have one and only one set as valid and primary'
    super
  end

  def validate_each(record, attribute, value)
    @record = record
    @attribute = attribute
    @value = value

    add_error unless valid?
  end

  private

  def valid?
    not_deleted = value.reject(&:marked_for_destruction?)
    return false if not_deleted.select(&:historic).any?(&options[:primary_field])
    non_historic = not_deleted.reject(&:historic)
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
