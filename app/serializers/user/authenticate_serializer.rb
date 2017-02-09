class User::AuthenticateSerializer < ServiceSerializer
  type :authenticate

  attributes :json_web_token

  delegate :json_web_token,
           to: :object
end
