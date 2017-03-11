module Filtering
  DatetimeCastingError = Class.new(StandardError)
  DATE_RANGE_REGEX = /(\d{4}\-\d{2}\-\d{2})(\.\.\.?)(\d{4}\-\d{2}\-\d{2})/
  DATETIME_RANGE_REGEX = /(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)(\.\.\.?)(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)/
  DEFAULT_PERMITTED_FILTERS = %w( updated_at ).freeze

  private

  def permitted_filters_with_defaults
    permitted_filters + DEFAULT_PERMITTED_FILTERS
  end

  def permitted_filters
    []
  end

  def filter_params
    return {} unless params[:filter]
    params[:filter]
      .map { |k, v| { k.underscore.to_sym => v } }
      .reduce({}, :merge)
      .keep_if { |k, _| permitted_filters_with_defaults.include? k }
      .transform_values { |v| cast_filter_value(v) }
  end

  def cast_filter_value(value)
    cast_filter_value!(value)
  rescue DatetimeCastingError
    raise_bad_request
  end

  def cast_filter_value!(value)
    case value
    when DATE_RANGE_REGEX, DATETIME_RANGE_REGEX
      cast_to_datetime_range($LAST_MATCH_INFO)
    else
      raise_if_bad_date_range_value(value)
    end
  end

  def raise_if_bad_date_range_value(value)
    return raise_bad_request if value_includes_a_date?(value)
    value
  end

  def value_includes_a_date?(value)
    return false unless value.is_a?(String)
    return false if value.to_s.match(UUID_REGEX)
    Date.parse(value.to_s)
  rescue ArgumentError
    false
  end

  def cast_to_datetime_range(match_data)
    start_datetime = DateTime.parse(match_data[1])
    end_datetime   = DateTime.parse(match_data[3])
    exclusive      = match_data[2].length == 3

    Range.new(start_datetime, end_datetime, exclusive)
  rescue ArgumentError
    raise DatetimeCastingError
  end

  def raise_bad_request
    raise Exceptions::BadRequestError,
          "Wrong format of date range, should follow 'YYYY-MM-DD...YYYY-MM-DD' for dates and 'YYYY-MM-DDThh:mm:ssZ...YYYY-MM-DDThh:mm:ssZ' for datetimes"
  end
end
