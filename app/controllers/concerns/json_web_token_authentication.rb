module JsonWebTokenAuthentication
  private

  def jwt_authorize!
    raise Exceptions::AuthenticationError unless user_id_in_token?
  rescue JWT::VerificationError, JWT::DecodeError
    raise Exceptions::AuthenticationError
  end

  # The check for user_uuid should be removed 30 days after the following PR is merged to master
  # https://github.com/CruGlobal/mpdx_api/pull/993
  def user_id_in_token?
    http_token && jwt_payload && (jwt_payload['user_id'].present? || jwt_payload['user_uuid'].present?)
  end

  def http_token
    return @http_token ||= auth_header.split(' ').last if auth_header.present?
    return @http_token ||= params[:access_token] if params[:access_token]
  end

  def auth_header
    request.headers['Authorization']
  end

  def jwt_payload
    @jwt_payload ||= JsonWebToken.decode(http_token) if http_token
  end
end
