class ApiController < ActionController::API
  rescue_from Exceptions::AuthenticationError, with: :render_401
  rescue_from ActiveRecord::RecordNotFound,    with: :render_404
  before_action :verify_request

  MEDIA_TYPE_MATCHER = /.+".+"[^,]*|[^,]+/
  ALL_MEDIA_TYPES = '*/*'.freeze

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

  def render_404
    render_error(title: 'Not Found', status: :not_found)
  end

  def render_403
    render_403_with_title('Forbidden')
  end

  def render_403_with_title(title)
    render_error(title: title, status: :forbidden)
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
    content_header = request.headers['CONTENT_TYPE']
    render_415 unless content_header == 'application/vnd.api+json'
  end

  def verify_request_accept_type
    render_406 unless valid_accept_header?
  end

  def valid_accept_header?
    media_types = given_media_types('Accept')

    media_types.blank? || media_types.any? do |media_type|
      (media_type == 'application/vnd.api+json' || media_type.start_with?(ALL_MEDIA_TYPES))
    end
  end

  def given_media_types(header)
    (request.headers[header] || '')
      .scan(MEDIA_TYPE_MATCHER)
      .to_a
      .map(&:strip)
  end
end
