class Api::V2Controller < ApiController
  include Pundit
  include Filtering
  include Sorting
  include Pagination

  before_action :jwt_authorize!
  before_action :transform_params_field_names, only: [:create, :update]
  after_action :verify_authorized, except: :index

  rescue_from Pundit::NotAuthorizedError, with: :render_403

  protected

  def current_user
    @current_user ||= User.find(jwt_payload['user_id']) if jwt_payload
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
      filters: filter_params
    }
  end

  def permitted_filters
    raise NotImplementedError,
          'This method needs to be implemented in your controller'
  end

  def transform_params_field_names
    new_hash = {}

    params[:data][:attributes].each do |key, value|
      new_key = key.tr('-', '_')
      new_hash[new_key.to_sym] = value
    end

    params[:data][:attributes] = new_hash
  end
end
