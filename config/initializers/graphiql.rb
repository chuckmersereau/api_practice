GraphiQL::Rails.config.headers['Authorization'] = -> (bearer) do
  if User.exists?
    user = User.find_by(id: 2) || User.first
    return JsonWebToken.encode(user_id: user.id)
  end
end
