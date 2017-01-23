class Api::V2Controller < ApiController
  include Pundit
  include Filtering
  include Sorting
  include Pagination
  include UuidToIdTransformer
  include Including
  include Fields

  before_action :jwt_authorize!
  before_action :verify_primary_id_placement,             only: [:create]
  before_action :transform_id_param_to_uuid_attribute,    only: [:create, :update]
  before_action :transform_uuid_attributes_params_to_ids, only: [:create, :update]
  before_action :transform_uuid_filters_params_to_ids,    only: :index

  after_action  :verify_authorized, except: :index

  rescue_from Pundit::NotAuthorizedError, with: :render_403

  protected

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
      sort: sorting_param,
      filter: filter_params
    }
  end

  def permitted_filters
    raise NotImplementedError,
          'This method needs to be implemented in your controller'
  end

  def persistence_context
    action_name == 'update' ? :update_from_controller : :create
  end

  def transform_id_param_to_uuid_attribute
    return unless params[:data] && params[:data][:id] && params[:data][:attributes]

    data_attributes[:uuid] = params[:data][:id]
  end

  def data_attributes
    params[:data][:attributes] if params[:data]
  end

  def fetch_account_lists
    return current_user.account_lists unless params[:filter] && params[:filter][:account_list_id]
    fetch_account_list_with_filter
  end

  def fetch_account_list_with_filter
    @account_lists = current_user.account_lists.where(uuid: params[:filter][:account_list_id])
    render_404_with_detail(
      "Resource 'account_list' with id '#{params[:filter][:account_list_id]}' does not exist."
    ) if @account_lists.empty?
    @account_lists
  end

  def verify_primary_id_placement
    if data_attributes && data_attributes[:id]
      render_403_with_title('A primary `id` cannot be sent at `/data/attributes/id`, it must be sent at `/data/id`')
    end
  end
end
