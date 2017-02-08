class Api::V2::BulkController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  before_action :transform_uuid_attributes_params_to_ids, only: [:create, :update]
  before_action :transform_uuid_filters_params_to_ids,    only: :index
end
