# rubocop:disable Style/ModuleFunction
module CastedValueValidator
  extend self

  DATE_FIELD_ENDINGS ||= %w(_at _date _range).freeze

  def validate!(attribute:, value:)
    if DATE_FIELD_ENDINGS.any? { |ending| attribute.to_s.end_with?(ending) }
      ensure_date_formatting(value)
    end
  end

  private

  def ensure_date_formatting(value)
    case value
    when Date, DateTime
      true
    when Range
      ensure_date_formatting(value.begin)
      ensure_date_formatting(value.end)
    else
      raise DateTimeCastingError
    end
  end

  class DateTimeCastingError < StandardError; end
end
