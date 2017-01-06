class Api::V2Controller < ApiController
  include Pundit
  include Filtering
  include Sorting
  include Pagination
  include UuidToIdTransformer
  include Including
  include Fields

  before_action :jwt_authorize!
  before_action :transform_uuid_attributes_params_to_ids, :transform_id_attribute_key_to_uuid, only: [:create, :update]
  before_action :transform_uuid_filters_params_to_ids, only: :index
  after_action :verify_authorized, except: :index

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

  def transform_id_attribute_key_to_uuid
    return unless data_attributes[:id]
    data_attributes[:uuid] = data_attributes[:id]
    data_attributes.delete(:id)
  end

  def data_attributes
    params[:data][:attributes]
  end

  def fetch_account_lists
    return current_user.account_lists unless params[:filter] && params[:filter][:account_list_id]
    [current_user.account_lists.find_by!(uuid: params[:filter][:account_list_id])]
  end
end
