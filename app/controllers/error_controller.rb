class ErrorController < ApiController
  rescue_from ActionController::RoutingError, with: :render_404_from_exception

  def not_found
    raise ActionController::RoutingError.new('Route not found', [])
  end
end
