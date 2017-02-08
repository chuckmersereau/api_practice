class Api::V2::User::AuthenticatesController < Api::V2Controller
  skip_before_action :jwt_authorize!, :validate_and_transform_json_api_params
  skip_after_action :verify_authorized

  def create
    require_cas_ticket
    validate_cas_ticket
    load_user
    render_json_web_token
  end

  private

  def require_cas_ticket
    raise ActionController::ParameterMissing if cas_ticket_param.blank?
  rescue ActionController::ParameterMissing
    raise(Exceptions::BadRequestError, 'Expected a cas_ticket in the json body, like {"data":{"cas_ticket":"..."}}')
  end

  def validate_cas_ticket
    cas_ticket_validator.validate
  end

  def cas_ticket_validator
    @cas_ticket_validator ||= CasTicketValidatorService.new(ticket: cas_ticket_param, service: service)
  end

  def guid
    cas_ticket_validator.attribute('ssoGuid')
  end

  def load_user
    @user ||= ::User.find_by_guid(guid)
    raise Exceptions::AuthenticationError unless @user
    @user
  end

  def json_web_token
    JsonWebToken.encode(user_id: load_user.id)
  end

  def cas_ticket_param
    params.require(:data)[:cas_ticket]
  end

  # The service should be a predetermined service URL for the MPDX API.
  # It will be used by the API when validating the ticket (and also by clients to request a ticket).
  # It's recommended to use the URL that the ticket is sent to on the MPDX API for consistency, which is this controller.
  # Expect it to be "https://api.mpdx.org/api/v2/user/authenticate"
  def service
    [request.base_url, request.path].join
  end

  def render_json_web_token
    render json: { data: { json_web_token: json_web_token } },
           status: :ok
  end
end
