class ApiController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound,    with: :render_404_from_exception
  rescue_from ActiveRecord::RecordNotUnique,   with: :render_409_from_exception
  rescue_from Exceptions::AuthenticationError, with: :render_401_from_exception
  rescue_from Exceptions::BadRequestError,     with: :render_400_from_exception

  rescue_from JsonApiService::ForeignKeyPresentError,          with: :render_409_from_exception
  rescue_from JsonApiService::InvalidPrimaryKeyPlacementError, with: :render_409_from_exception
  rescue_from JsonApiService::InvalidTypeError,                with: :render_409_from_exception
  rescue_from JsonApiService::MissingTypeError,                with: :render_409_from_exception

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

  def conflict_error?(resource)
    resource.errors.full_messages.any? do |error_message|
      error_message.include?(ApplicationRecord::CONFLICT_ERROR_MESSAGE)
    end
  end

  def current_account_list
    @account_list ||= current_user.account_lists
                                  .find_by(id: params[:account_list_id])
  end

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
    render_error(title: title, detail: detail, status: '400')
  end

  def render_400_from_exception(exception)
    render_400(detail: exception&.message)
  end

  def render_with_resource_errors(resource)
    if resource.is_a? Hash
      render_error(hash: resource, status: '400')
    elsif conflict_error?(resource)
      render_409(detail: detail_for_resource_first_error(resource), resource: resource)
    else
      render_400_with_errors(resource)
    end
  end

  def render_400_with_errors(resource_or_hash)
    render_error(resource: resource_or_hash, status: '400')
  end

  def render_401(title: 'Unauthorized', detail: nil)
    render_error(title: title, detail: detail, status: '401')
  end

  def render_401_from_exception(exception)
    render_401(detail: exception&.message)
  end

  def render_403(title: 'Forbidden', detail: nil)
    render_error(title: title, detail: detail, status: '403')
  end

  def render_403_from_exception(exception)
    return render_403 unless exception&.record.try(:id)
    type = JsonApiService.configuration.resource_lookup.find_type_by_class(exception&.record&.class)
    render_403(detail: 'Not allowed to perform that action on the '\
                   "resource with ID #{exception.record.id} of type #{type}")
  end

  def render_404(title: 'Not Found', detail: nil)
    render_error(title: title, detail: detail, status: '404')
  end

  def render_404_from_exception(exception)
    render_404(detail: exception&.message)
  end

  def render_406
    render_error(title: 'Not Acceptable', status: '406')
  end

  def render_409(title: 'Conflict', detail: nil, resource: nil)
    render_error(title: title, detail: detail, status: '409', resource: resource)
  end

  def render_409_from_exception(exception)
    detail = exception&.cause&.message || exception&.message || 'Conflict'
    render_409(detail: detail)
  end

  def render_415
    render_error(title: 'Unsupported Media Type', status: '415')
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
    return true if self.class.supported_accept_header_content_types.include?(:any)
    media_types = given_media_types('Accept')

    media_types.blank? || media_types.any? do |media_type|
      (self.class.supported_accept_header_content_types.include?(media_type) || media_type.start_with?(ALL_MEDIA_TYPES))
    end
  end

  def valid_content_type_header?
    return true if self.class.supported_content_types.include?(:any)

    content_types = request.headers['CONTENT_TYPE']&.gsub(',', ';')&.split(';') || []
    (self.class.supported_content_types & content_types).present?
  end

  def verify_request
    verify_request_content_type
    verify_request_accept_type
  end

  def verify_request_accept_type
    render_406 unless valid_accept_header?
  end

  def verify_request_content_type
    render_415 unless valid_content_type_header?
  end

  def detail_for_resource_first_error(resource)
    first_key = resource.errors.messages.keys.first
    val = resource.errors.messages.select do |key, _value|
      key.to_s.include?('updated_in_db_at')
    end.values.flatten.last

    "#{first_key} #{val}"
  end
end
