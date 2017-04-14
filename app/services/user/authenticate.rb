class User::Authenticate < ActiveModelSerializers::Model
  attr_accessor :user

  def initialize(attributes = {})
    super
  end

  def json_web_token
    @json_web_token ||= ::JsonWebToken.encode(user_uuid: user.uuid)
  end
end
