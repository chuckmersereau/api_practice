class CurrentContext
  attr_reader :user, :user_data

  def initialize(user, user_data)
    @user = user
    @user_data = user_data
  end
end
