class ApiController < ActionController::API
  rescue_from Exceptions::AuthenticationError, with: :render_401_from_exception
  rescue_from ActiveRecord::RecordNotFound,    with: :render_404_from_exception
  rescue_from ActiveRecord::RecordNotUnique,   with: :render_409_from_exception
  rescue_from Exceptions::BadRequestError,     with: :render_400_from_exception

  before_action :verify_request

  MEDIA_TYPE_MATCHER = /.+".+"[^,]*|[^,]+/
  ALL_MEDIA_TYPES = '*/*'.freeze
  DEFAULT_SUPPORTED_CONTENT_TYPE = 'application/vnd.api+json'.freeze

  class << self
    def supports_content_types(*content_types)
      @supported_content_types = content_types.compact.presence
    end

    def supports_accept_header_content_types(*content_types)
      @supported_accept_header_content_types = content_types.compact.presence
    end

    def supported_content_types
      @supported_content_types ||= []
      @supported_content_types.presence || [DEFAULT_SUPPORTED_CONTENT_TYPE]
    end

    def supported_accept_header_content_types
      @supported_accept_header_content_types ||= []
      @supported_accept_header_content_types.presence || [DEFAULT_SUPPORTED_CONTENT_TYPE]
    end
  end

  protected

  def given_media_types(header)
    (request.headers[header] || '')
      .scan(MEDIA_TYPE_MATCHER)
      .map(&:strip)
  end

  def render_200
    head :ok
  end

  def render_201
    head :created
  end

  def render_400(title: 'Bad Request', detail: nil)
    render_error(title: title, detail: detail, status: :bad_request)
  end

  def render_400_from_exception(exception)
    render_400(detail: exception&.message)
  end

  def render_with_resource_errors(resource)
    if resource.is_a? Hash
      render_error(hash: resource, status: :bad_request)
    elsif resource.errors.keys.include?(:updated_in_db_at)
      render_409(detail: detail_for_resource_first_error(resource))
    else
      render_400_with_errors(resource)
    end
  end

  def render_400_with_errors(resource_or_hash)
    render_error(resource: resource_or_hash, status: :bad_request)
  end

  def render_401(title: 'Unauthorized', detail: nil)
    render_error(title: title, detail: detail, status: :unauthorized)
  end

  def render_401_from_exception(exception)
    render_401(detail: exception&.message)
  end

  def render_403(title: 'Forbidden', detail: nil)
    render_error(title: title, detail: detail, status: :forbidden)
  end

  def render_403_from_exception(exception)
    uuid = exception&.record&.uuid
    detail = uuid ? "Not allowed to perform that action on the resource with ID #{uuid}" : nil

    render_403(detail: detail)
  end

  def render_404(title: 'Not Found', detail: nil)
    render_error(title: title, detail: detail, status: '404')
  end

  def render_404_from_exception(exception)
    render_404(detail: exception&.message)
  end

  def render_406
    render_error(title: 'Not Acceptable', status: :not_acceptable)
  end

  def render_409(title: 'Conflict', detail: nil)
    render_error(title: title, detail: detail, status: :conflict)
  end

  def render_409_from_exception(exception)
    detail = exception&.cause&.message || 'Conflict'
    render_409(detail: detail)
  end

  def render_415
    render_error(title: 'Unsupported Media Type', status: :unsupported_media_type)
  end

  def render_error(hash: nil, resource: nil, title: nil, detail: nil, status:)
    serializer = ErrorSerializer.new(
      hash: hash,
      resource: resource,
      title: title,
      detail: detail,
      status: status
    )

    render json: serializer,
           status: status
  end

  def success_status
    if action_name == 'create'
      :created
    else
      :ok
    end
  end

  def valid_accept_header?
    media_types = given_media_types('Accept')

    media_types.blank? || media_types.any? do |media_type|
      (self.class.supported_accept_header_content_types.include?(media_type) || media_type.start_with?(ALL_MEDIA_TYPES))
    end
  end

  def verify_request
    verify_request_content_type
    verify_request_accept_type
  end

  def verify_request_accept_type
    render_406 unless valid_accept_header?
  end

  def verify_request_content_type
    content_type = request.headers['CONTENT_TYPE']&.split(';')&.first
    render_415 unless self.class.supported_content_types.include?(content_type)
  end

  def detail_for_resource_first_error(resource)
    key = resource.errors.messages.keys.first
    val = resource.errors.messages[:updated_in_db_at].first
    "#{key} #{val}"
  end
end
