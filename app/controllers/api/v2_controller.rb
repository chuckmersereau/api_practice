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

  rescue_from Pundit::NotAuthorizedError, with: :render_403_from_exception

  before_action :authenticate!
  before_action :validate_and_transform_json_api_params
  before_action :update_current_user_tracked_fields

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

  def permit_coach?
    false
  end

  private

  # The check for user_uuid should be removed 30 days after the following PR is merged to master
  # https://github.com/CruGlobal/mpdx_api/pull/993
  def fetch_current_user
    # See JsonWebToken::Middleware and application.rb where the middleware is initialized

    jwt_payload = request.env['auth.jwt_payload']

    return unless (jwt_payload.try(:[], 'user_id') || jwt_payload.try(:[], 'user_uuid')) && jwt_payload.try(:[], 'exp')

    User.find_by(id: jwt_payload['user_id'] || jwt_payload['user_uuid'])
  end

  def authenticate!
    raise Exceptions::AuthenticationError unless current_user
  end

  def meta_hash(resources)
    {
      pagination: pagination_meta_params(resources),
      sort: sorting_param_applied_to_query,
      filter: permitted_filter_params_with_ids
    }
  end

  def permitted_filter_params_with_ids
    @original_params[:filter]&.slice(*filter_params.keys) || {}
  end

  def persistence_context
    action_name == 'update' ? :update_from_controller : :create
  end

  def data_attributes
    params.dig(:data, :attributes)
  end

  def fetch_account_lists
    unless account_list_filter
      return current_user.account_lists unless permit_coach?
      return current_user.readable_account_lists
    end
    @account_lists = fetch_account_list_with_filter
    return @account_lists if @account_lists.present?
    raise ActiveRecord::RecordNotFound,
          "Resource 'AccountList' with id '#{account_list_filter}' does not exist."
  end

  def account_list_filter
    params.dig(:filter, :account_list_id) if permitted_filters.include?(:account_list_id)
  end

  def fetch_account_list_with_filter
    return current_user.account_lists.where(id: account_list_filter) unless permit_coach?
    current_user.readable_account_lists.where(id: account_list_filter)
  end

  def verify_primary_id_placement
    render_403(title: 'A primary `id` cannot be sent at `/data/attributes/id`, it must be sent at `/data/id`') if params.dig(:data, :attributes, :id)
  end

  def scope_request_to_time_zone(&block)
    Time.use_zone(current_time_zone, &block)
  end

  def scope_request_to_locale
    I18n.locale = locale_from_header_or_current_user.try(:tr, '-', '_') || 'en_US'
    yield
  ensure
    I18n.locale = 'en_US'
  end

  def locale_from_header_or_current_user
    request.env['HTTP_ACCEPT_LANGUAGE'].try(:split, /[,,;]/).try(:first) || current_user&.locale
  end

  def validate_and_transform_json_api_params
    @original_params = params
    @_params = JsonApiService.consume(params: params, context: self)
  end

  def update_current_user_tracked_fields
    return unless current_user
    return if current_user.current_sign_in_at.present? && current_user.current_sign_in_at > 12.hours.ago
    current_user.update_tracked_fields!(request)
  end
end
