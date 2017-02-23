require 'json_api_service'

class Api::V2Controller < ApiController
  include Fields
  include Filtering
  include Including
  include Pagination
  include Pundit
  include PunditHelpers
  include ResourceType
  include Sorting
  include UuidToIdTransformer

  rescue_from Pundit::NotAuthorizedError, with: :render_403_from_exception

  before_action :jwt_authorize!
  before_action :validate_and_transform_json_api_params

  after_action  :verify_authorized, except: :index
  around_action :scope_request_to_time_zone

  protected

  def current_time_zone
    if current_user&.time_zone
      Time.find_zone(current_user.time_zone) || Time.zone
    else
      Time.zone
    end
  end

  def current_user
    @current_user ||= User.find(jwt_payload['user_id']) if jwt_payload
  end

  def account_lists
    @account_lists ||= fetch_account_lists
  end

  private

  def jwt_authorize!
    raise Exceptions::AuthenticationError unless user_id_in_token?
  rescue JWT::VerificationError, JWT::DecodeError
    raise Exceptions::AuthenticationError
  end

  def user_id_in_token?
    http_token && jwt_payload && jwt_payload['user_id'].to_i
  end

  def http_token
    @http_token ||= auth_header.split(' ').last if auth_header.present?
  end

  def auth_header
    request.headers['Authorization']
  end

  def jwt_payload
    @jwt_payload ||= JsonWebToken.decode(http_token) if http_token
  end

  def meta_hash(resources)
    {
      pagination: pagination_meta_params(resources),
      sort: sorting_param_applied_to_query,
      filter: filter_params
    }
  end

  def persistence_context
    action_name == 'update' ? :update_from_controller : :create
  end

  def transform_id_param_to_uuid_attribute
    return unless params[:data] && params[:data][:id] && params[:data][:attributes]

    data_attributes[:uuid] = params[:data][:id]
  end

  def data_attributes
    params.dig(:data, :attributes)
  end

  def fetch_account_lists
    return current_user.account_lists unless account_list_filter
    @account_lists = fetch_account_list_with_filter
    return @account_lists if @account_lists.present?
    raise ActiveRecord::RecordNotFound,
          "Resource 'AccountList' with id '#{account_list_filter}' does not exist."
  end

  def account_list_filter
    params.dig(:filter, :account_list_id)
  end

  def fetch_account_list_with_filter
    current_user.account_lists.where(id: account_list_filter)
  end

  def verify_primary_id_placement
    if params.dig(:data, :attributes, :id)
      render_403(title: 'A primary `id` cannot be sent at `/data/attributes/id`, it must be sent at `/data/id`')
    end
  end

  def scope_request_to_time_zone(&block)
    Time.use_zone(current_time_zone, &block)
  end

  def validate_and_transform_json_api_params
    @original_params = params
    @_params = JsonApiService.consume(params: params, context: self)
  end
end
