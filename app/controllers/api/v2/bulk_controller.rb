class Api::V2::BulkController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  before_action :validate_and_transform_bulk_json_api_params

  private

  def validate_and_transform_bulk_json_api_params
    @original_params = params
    data_array = params.dig(:data) || []

    bulk_data = data_array.map do |data|
      data[:action] = params[:action]
      data[:controller] = params[:controller]

      data = ActionController::Parameters.new(data)

      JsonApiService.consume(params: data, context: self)
    end

    @_params = ActionController::Parameters.new(
      data: bulk_data,
      action: params[:action],
      controller: params[:controller]
    )
  end
end
