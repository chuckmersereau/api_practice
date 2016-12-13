class ApiController < ActionController::API
  rescue_from Exceptions::AuthenticationError, with: :render_401
  rescue_from ActiveRecord::RecordNotFound,    with: :render_404

  protected

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

  def render_404
    render_error(title: 'Not Found', status: :not_found)
  end

  def render_403
    render_error(title: 'Forbidden', status: :forbidden)
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
end
