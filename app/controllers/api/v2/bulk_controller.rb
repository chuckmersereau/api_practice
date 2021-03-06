class Api::V2::BulkController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  before_action :reject_if_in_batch_request
  before_action :validate_and_transform_bulk_json_api_params

  private

  def validate_and_transform_bulk_json_api_params
    @original_params = params

    @_params = params.merge(
      data: bulk_data_from_array_params(data_array_params)
    )
  end

  def bulk_data_from_array_params(data_array_params)
    data_array_params.map do |data|
      missing_id_error unless data['data']['id']

      data[:action] = params[:action]
      data[:controller] = params[:controller]

      data = ActionController::Parameters.new(data)

      JsonApiService.consume(params: data, context: self)
    end
  end

  def data_array_params
    params.dig(:data) || []
  end

  def fetch_account_list_with_filter
    current_user.account_lists.where(id: account_list_filter)
  end

  def missing_id_error
    raise Exceptions::BadRequestError,
          'An `id` is required for every top-level object within the /data array being sent in bulk requests'
  end

  def scope_exists!(scope)
    return scope if scope.exists?

    # exception pulled from
    # https://github.com/rails/rails/blob/4-2-stable/activerecord/lib/active_record/relation/finder_methods.rb#L489
    raise ActiveRecord::RecordNotFound, "Couldn't find #{scope.klass.name} with [#{scope.arel.where_sql}]"
  end
end
