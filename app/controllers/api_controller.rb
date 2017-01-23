class ApiController < ActionController::API
  rescue_from Exceptions::AuthenticationError, with: :render_401
  rescue_from ActiveRecord::RecordNotFound,    with: :render_404
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

  def verify_request
    verify_request_content_type
    verify_request_accept_type
  end

  def render_200
    head :ok
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

  def render_201
    head :created
  end

  def render_415
    render_error(title: 'Unsupported Media Type', status: :unsupported_media_type)
  end

  def render_406
    render_error(title: 'Not Acceptable', status: :not_acceptable)
  end

  def render_404(detail = nil)
    render_error(title: 'Not Found', detail: detail, status: :not_found)
  end

  def render_403_from_exception(exception)
    uuid = exception.try(:record).try(:uuid)
    detail = uuid ? "Not allowed to perform that action on the resource with ID #{uuid}" : nil
    render_403(detail: detail)
  end

  def render_403(title: 'Forbidden', detail: nil)
    render_error(title: title, detail: detail, status: :forbidden)
  end

  def render_401
    render_error(title: 'Unauthorized', status: :unauthorized)
  end

  def render_400
    head :bad_request
  end

  def render_400_with_errors(resource_or_hash)
    case resource_or_hash
    when Hash
      render_error(hash: resource_or_hash, status: :bad_request)
    else
      render_error(resource: resource_or_hash, status: :bad_request)
    end
  end

  def success_status
    if action_name == 'create'
      :created
    else
      :ok
    end
  end

  def verify_request_content_type
    content_type = request.headers['CONTENT_TYPE'].try(:split, ';').try(:first)
    render_415 unless self.class.supported_content_types.include?(content_type)
  end

  def verify_request_accept_type
    render_406 unless valid_accept_header?
  end

  def valid_accept_header?
    media_types = given_media_types('Accept')

    media_types.blank? || media_types.any? do |media_type|
      (self.class.supported_accept_header_content_types.include?(media_type) || media_type.start_with?(ALL_MEDIA_TYPES))
    end
  end

  def given_media_types(header)
    (request.headers[header] || '')
      .scan(MEDIA_TYPE_MATCHER)
      .map(&:strip)
  end
end
