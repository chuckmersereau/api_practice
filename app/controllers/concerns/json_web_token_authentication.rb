module JsonWebTokenAuthentication
  private

  def jwt_authorize!
    raise Exceptions::AuthenticationError unless user_uuid_in_token?
  rescue JWT::VerificationError, JWT::DecodeError
    raise Exceptions::AuthenticationError
  end

  def user_uuid_in_token?
    http_token && jwt_payload && jwt_payload['user_uuid'].to_i
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
