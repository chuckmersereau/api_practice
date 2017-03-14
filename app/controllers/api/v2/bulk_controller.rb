class Api::V2::BulkController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  before_action :validate_and_transform_bulk_json_api_params

  private

  def validate_and_transform_bulk_json_api_params
    @original_params = params

    @_params = ActionController::Parameters.new(
      data: bulk_data_from_array_params(data_array_params),
      action: params[:action],
      controller: params[:controller]
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

  def missing_id_error
    raise Exceptions::BadRequestError,
          'An `id` is required for every top-level object within the /data array being sent in bulk requests'
  end
end
