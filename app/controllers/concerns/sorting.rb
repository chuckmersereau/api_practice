module Sorting
  PERMITTED_SORTING_PARAMS = %w(
    created_at
    updated_at).freeze

  private

  def descending_sorting_params?
    params[:sort].starts_with?('-')
  end

  def multiple_sorting_params?
    params[:sort].include?(',')
  end

  def permitted_sorting_params
    PERMITTED_SORTING_PARAMS
  end

  def raise_error_if_multiple_sorting_params
    raise Exceptions::BadRequestError, 'The current API does not support multiple sorting parameters.' if multiple_sorting_params?
  end

  def raise_error_unless_sorting_param_allowed
    raise Exceptions::BadRequestError, "Sorting by '#{params[:sort]}' is not supported for this endpoint." unless sorting_param_allowed?
  end

  def sorting_param
    return nil unless params[:sort]

    raise_error_if_multiple_sorting_params
    raise_error_unless_sorting_param_allowed
    transformed_sorting_params
  end

  def sorting_param_allowed?
    permitted_sorting_params.include?(params[:sort]&.tr('-', ''))
  end

  def sorting_param_applied_to_query
    params[:sort] if sorting_param_allowed?
  end

  def transformed_sorting_params
    return "#{params[:sort].tr('-', '')} DESC" if descending_sorting_params?

    "#{params[:sort]} ASC"
  end
end
