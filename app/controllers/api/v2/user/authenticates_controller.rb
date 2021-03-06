class Api::V2::User::AuthenticatesController < Api::V2Controller
  skip_before_action :authenticate!, :validate_and_transform_json_api_params
  skip_after_action :verify_authorized

  def create
    require_cas_ticket
    validate_cas_ticket
    update_tracked_fields
    queue_imports
    render_authenticate
  end

  private

  def require_cas_ticket
    raise ActionController::ParameterMissing if cas_ticket_param.blank?
  rescue ActionController::ParameterMissing
    raise Exceptions::BadRequestError, 'Expected a cas_ticket to be provided in the attributes'
  end

  def validate_cas_ticket
    cas_ticket_validator.validate
  end

  def cas_ticket_validator
    @cas_ticket_validator ||= CasTicketValidatorService.new(ticket: cas_ticket_param, service: service)
  end

  def load_user
    @user ||= UserFromCasService.find_or_create(cas_ticket_validator.attributes)

    raise Exceptions::AuthenticationError unless @user
    @user
  end

  def build_authenticate
    @authenticate ||= ::User::Authenticate.new(authenticate_params)
  end

  def authenticate_params
    { user: load_user }
  end

  def cas_ticket_param
    params.require('data').require('attributes')['cas_ticket']
  end

  def queue_imports
    load_user.queue_imports
  end

  # The service should be a predetermined service URL for the MPDX API.
  # It will be used by the API when validating the ticket (and also by clients to request a ticket).
  # It's recommended to use the URL that the ticket is sent to on the MPDX API for consistency, which is this controller.
  # Expect it to be "https://api.mpdx.org/api/v2/user/authenticate"
  def service
    [request.base_url, request.path].join
  end

  def render_authenticate
    render json: build_authenticate,
           status: :ok
  end

  def update_tracked_fields
    load_user.update_tracked_fields!(request)
  end
end
