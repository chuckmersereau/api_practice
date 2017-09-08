require 'json_api_service'

class Api::V2Controller < ApiController
  include BatchRequestHelpers
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

  before_action :authenticate!
  before_action :validate_and_transform_json_api_params

  after_action  :verify_authorized, except: :index
  around_action :scope_request_to_time_zone, :scope_request_to_locale

  protected

  def current_time_zone
    if current_user&.time_zone
      Time.find_zone(current_user.time_zone) || Time.zone
    else
      Time.zone
    end
  end

  def current_user
    @current_user ||= fetch_current_user
  end

  def account_lists
    @account_lists ||= fetch_account_lists
  end

  private

  def fetch_current_user
    # See JsonWebToken::Middleware and application.rb where the middleware is initialized

    jwt_payload = request.env['auth.jwt_payload']

    return unless jwt_payload.try(:[], 'user_uuid') && jwt_payload.try(:[], 'exp')

    User.find_by(uuid: jwt_payload['user_uuid'])
  end

  def authenticate!
    raise Exceptions::AuthenticationError unless current_user
  end

  def meta_hash(resources)
    {
      pagination: pagination_meta_params(resources),
      sort: sorting_param_applied_to_query,
      filter: permitted_filter_params_with_uuids
    }
  end

  def permitted_filter_params_with_uuids
    @original_params[:filter]&.slice(*filter_params.keys) || {}
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
    params.dig(:filter, :account_list_id) if permitted_filters.include?(:account_list_id)
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

  def scope_request_to_locale
    I18n.locale = current_user&.locale.try(:tr, '-', '_') || 'en_US'
    yield
  ensure
    I18n.locale = 'en_US'
  end

  def validate_and_transform_json_api_params
    @original_params = params
    @_params = JsonApiService.consume(params: params, context: self)
  end
end
