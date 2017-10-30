module Filtering
  DATE_REGEX = /(\d{4}\-\d{2}\-\d{2})/
  DATE_TIME_REGEX = /(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)/
  DATE_RANGE_REGEX = /(\d{4}\-\d{2}\-\d{2})(\.\.\.?)(\d{4}\-\d{2}\-\d{2})/
  DATE_TIME_RANGE_REGEX = /(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)(\.\.\.?)(\d{4}\-\d{2}\-\d{2}T\d{2}\:\d{2}\:\d{2}Z)/
  DEFAULT_PERMITTED_FILTERS = %i(updated_at).freeze

  def filter_params(filter_params = params[:filter])
    return {} unless filter_params

    filter_params
      .each_with_object({}) { |(key, value), hash| hash[key.to_s.underscore.to_sym] = value }
      .keep_if { |key, _| permitted_filters_with_defaults.include?(key) }
      .map { |key, value| { key => cast_filter_value(value) } }
      .reduce({}, :merge)
      .each { |key, value| validate_casted_filter_value!(key, value) }
  end

  private

  def cast_filter_value(value)
    case value
    when DATE_RANGE_REGEX, DATE_TIME_RANGE_REGEX
      cast_to_datetime_range($LAST_MATCH_INFO)
    when DATE_REGEX
      cast_date_to_datetime_range($LAST_MATCH_INFO)
    when DATE_TIME_REGEX
      cast_to_datetime($LAST_MATCH_INFO)
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
    match_data[0] # return the original string
  end

  def cast_date_to_datetime_range(match_data)
    datetime = DateTime.parse(match_data[1])
    start_datetime = datetime.beginning_of_day
    end_datetime   = datetime.end_of_day

    Range.new(start_datetime, end_datetime)
  rescue ArgumentError
    match_data[0] # return the original string
  end

  def cast_to_datetime(match_data)
    DateTime.parse(match_data[1])
  rescue ArgumentError
    match_data[0] # return the original string
  end

  def invalid_date_range_format_message(key)
    "Wrong format of date range for filter '#{key}', should follow 'YYYY-MM-DD...YYYY-MM-DD' for dates and 'YYYY-MM-DDThh:mm:ssZ...YYYY-MM-DDThh:mm:ssZ' for datetimes"
  end

  def permitted_filters
    []
  end

  def permitted_filters_with_defaults
    permitted_filters + DEFAULT_PERMITTED_FILTERS
  end

  def raise_invalid_date_range_message(key)
    raise Exceptions::BadRequestError, invalid_date_range_format_message(key)
  end

  def excluded_filter_keys_from_casting_validation
    []
  end

  def validate_casted_filter_value!(key, value)
    return if key.in? excluded_filter_keys_from_casting_validation
    CastedValueValidator.validate!(attribute: key, value: value)
  rescue CastedValueValidator::DateTimeCastingError
    raise_invalid_date_range_message(key)
  end
end
