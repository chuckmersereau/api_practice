module Filtering
  CastingError = Class.new(StandardError)
  DATE_RANGE_REGEX = /(\d{4}\-\d{2}\-\d{2})(\.\.\.?)(\d{4}\-\d{2}\-\d{2})/
  DATETIME_RANGE_REGEX = /(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)(\.\.\.?)(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)/

  private

  def filter_params
    return {} unless params[:filter]
    params[:filter]
      .map { |k, v| { k.underscore.to_sym => v } }
      .reduce({}, :merge)
      .keep_if { |k, _| permitted_filters.include? k }
      .transform_values { |v| cast_filter_value(v) }
  end

  def cast_filter_value(value)
    cast_filter_value!(value)
  rescue CastingError
    value
  end

  def cast_filter_value!(value)
    case value
    when DATE_RANGE_REGEX, DATETIME_RANGE_REGEX
      cast_to_datetime_range($LAST_MATCH_INFO)
    else
      value
    end
  end

  def cast_to_datetime_range(match_data)
    start_datetime = DateTime.parse(match_data[1])
    end_datetime   = DateTime.parse(match_data[3])
    exclusive      = match_data[2].length == 3

    Range.new(start_datetime, end_datetime, exclusive)
  rescue ArgumentError
    raise CastingError
  end
end
