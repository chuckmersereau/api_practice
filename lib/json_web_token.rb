module JsonWebToken
  module_function

  def encode(payload)
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def decode(token)
    return HashWithIndifferentAccess.new(JWT.decode(token, Rails.application.secrets.secret_key_base)[0])
  rescue JWT::DecodeError
    nil
  end
end
