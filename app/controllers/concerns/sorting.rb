module Sorting
  PERMITTED_SORTING_PARAM_DEFAULTS = %w(
    created_at
    updated_at
  ).freeze

  PERMIT_MULTIPLE_SORTING_PARAMS = false

  private

  def multiple_sorting_params?
    sorting_params_split.length > 1
  end

  def permitted_sorting_params
    []
  end

  def permitted_sorting_params_with_defaults
    permitted_sorting_params + PERMITTED_SORTING_PARAM_DEFAULTS
  end

  def raise_error_if_multiple_sorting_params_are_not_permitted
    raise Exceptions::BadRequestError, 'This endpoint does not support multiple sorting parameters.' if multiple_sorting_params? && !self.class::PERMIT_MULTIPLE_SORTING_PARAMS
  end

  def raise_error_unless_sorting_param_allowed
    raise Exceptions::BadRequestError, "Sorting by #{unpermitted_sorting_params.to_sentence} is not supported for this endpoint." if unpermitted_sorting_params.present?
  end

  def sorting_param
    return nil unless params[:sort]

    raise_error_if_multiple_sorting_params_are_not_permitted
    raise_error_unless_sorting_param_allowed
    convert_sorting_params_to_sql
  end

  def sorting_join
    sorting_params_split.collect do |param|
      next unless param.include? '.'
      resource_name = param.tr('-', '').split('.').first
      next if db_resource_name == resource_name
      resource_name.to_sym
    end.compact
  end

  def unpermitted_sorting_params
    sorting_params = sorting_params_split.collect { |param| db_column_for_permitted_param(param) }
    sorting_params - permitted_sorting_params_with_defaults
  end

  def db_column_for_permitted_param(param)
    param.split(' ').first.tr('-', '')
  end

  def sorting_params_split
    params[:sort]&.split(',') || []
  end

  def sorting_param_applied_to_query
    params[:sort] unless unpermitted_sorting_params.present?
  end

  def convert_sorting_params_to_sql
    sorting_params_split.collect do |param|
      [
        db_table_and_column_for_sorting_param(param),
        direction_for_sorting_param(param),
        null_order_for_sorting_param(param)
      ].select(&:present?).join(' ')
    end.join(', ')
  end

  def db_table_and_column_for_sorting_param(param)
    "\"#{db_table_for_sorting_param(param)}\".\"#{db_column_for_sorting_param(param)}\""
  end

  def db_table_for_sorting_param(param)
    return db_resource_name unless param.include? '.'
    param.split('.').first.tr('-', '').pluralize
  end

  def db_column_for_sorting_param(param)
    param.split('.').last.split(' ').first.tr('-', '')
  end

  def direction_for_sorting_param(param)
    param.starts_with?('-') ? 'DESC' : 'ASC'
  end

  def null_order_for_sorting_param(param)
    split_param = param.split(' ')
    return unless split_param.size > 1
    null_param = split_param.second
    raise Exceptions::BadRequestError, 'Bad format for sort param.' unless null_param.tr('-', '') == 'nulls'
    null_param.starts_with?('-') ? 'NULLS LAST' : 'NULLS FIRST'
  end

  def db_resource_name
    RESOURCE_TYPE_TO_DB_TYPE[resource_type] || resource_type.to_s
  end
end
